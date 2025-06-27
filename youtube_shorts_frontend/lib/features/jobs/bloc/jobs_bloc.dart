import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/jobs_repository.dart';
import 'jobs_event.dart';
import 'jobs_state.dart';

class JobsBloc extends Bloc<JobsEvent, JobsState> {
  final JobsRepository jobsRepository;
  Timer? _pollingTimer;
  String? _currentPollingJobId;

  JobsBloc(this.jobsRepository) : super(JobsInitial()) {
    on<LoadJobsEvent>(_onLoadJobs);
    on<LoadJobDetailsEvent>(_onLoadJobDetails);
    on<RefreshJobStatusEvent>(_onRefreshJobStatus);
    on<CreateJobEvent>(_onCreateJob);
    on<DeleteJobEvent>(_onDeleteJob);
    on<RefreshJobsEvent>(_onRefreshJobs);
    on<StartJobPollingEvent>(_onStartJobPolling);
    on<StopJobPollingEvent>(_onStopJobPolling);
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    return super.close();
  }

  Future<void> _onLoadJobs(
    LoadJobsEvent event,
    Emitter<JobsState> emit,
  ) async {
    print('🔄 LoadJobsEvent triggered with limit: ${event.limit}, offset: ${event.offset}');
    print('🔍 Current state before loading: ${state.runtimeType}');
    
    emit(JobsLoading());
    
    try {
      final jobs = await jobsRepository.getJobs(
        limit: event.limit,
        offset: event.offset,
      );
      print('📋 LoadJobs completed, emitting JobsListLoaded with ${jobs.length} jobs');
      emit(JobsListLoaded(jobs));
    } catch (e) {
      print('❌ LoadJobs failed: $e');
      emit(JobsError(message: e.toString()));
    }
  }

  Future<void> _onLoadJobDetails(
    LoadJobDetailsEvent event,
    Emitter<JobsState> emit,
  ) async {
    emit(JobsLoading());
    
    try {
      final job = await jobsRepository.getJobDetails(event.jobId);
      emit(JobDetailsLoaded(job));
    } catch (e) {
      emit(JobsError(message: e.toString()));
    }
  }

  Future<void> _onRefreshJobStatus(
    RefreshJobStatusEvent event,
    Emitter<JobsState> emit,
  ) async {
    try {
      final status = await jobsRepository.getJobStatus(event.jobId);
      emit(JobStatusUpdated(status));
    } catch (e) {
      emit(JobsError(message: e.toString()));
    }
  }

  Future<void> _onCreateJob(
    CreateJobEvent event,
    Emitter<JobsState> emit,
  ) async {
    emit(JobsLoading());
    
    try {
      final job = await jobsRepository.createJob(event.request);
      emit(JobCreated(job));
    } catch (e) {
      emit(JobsError(message: e.toString()));
    }
  }

  Future<void> _onDeleteJob(
    DeleteJobEvent event,
    Emitter<JobsState> emit,
  ) async {
    try {
      print('🗑️ Starting job deletion for ID: ${event.jobId}');
      await jobsRepository.deleteJob(event.jobId);
      print('✅ Job deleted successfully');
      
      // Emit simple deletion success state
      print('🔄 Emitting JobDeleted state with jobId: ${event.jobId}');
      final deleteState = JobDeleted(event.jobId);
      print('📤 About to emit state: ${deleteState.runtimeType}');
      print('📤 State details: $deleteState');
      print('📤 Current bloc state before emit: ${state.runtimeType}');
      emit(deleteState);
      print('✅ JobDeleted state emitted successfully');
      print('📤 Current bloc state after emit: ${state.runtimeType}');
    } catch (e) {
      print('❌ Error deleting job: $e');
      emit(JobsError(message: e.toString()));
    }
  }

  Future<void> _onRefreshJobs(
    RefreshJobsEvent event,
    Emitter<JobsState> emit,
  ) async {
    print('🔄 RefreshJobsEvent triggered');
    print('🔍 Current state before refresh: ${state.runtimeType}');
    
    try {
      final jobs = await jobsRepository.getJobs();
      print('📋 RefreshJobs completed, emitting JobsListLoaded with ${jobs.length} jobs');
      emit(JobsListLoaded(jobs));
    } catch (e) {
      print('❌ RefreshJobs failed: $e');
      emit(JobsError(message: e.toString()));
    }
  }

  void _onStartJobPolling(
    StartJobPollingEvent event,
    Emitter<JobsState> emit,
  ) {
    _stopPolling();
    _currentPollingJobId = event.jobId;
    
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) {
        if (!isClosed) {
          add(RefreshJobStatusEvent(event.jobId));
        }
      },
    );
  }

  void _onStopJobPolling(
    StopJobPollingEvent event,
    Emitter<JobsState> emit,
  ) {
    _stopPolling();
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _currentPollingJobId = null;
  }
} 
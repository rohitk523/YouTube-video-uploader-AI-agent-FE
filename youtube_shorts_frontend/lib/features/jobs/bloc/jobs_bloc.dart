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
    emit(JobsLoading());
    
    try {
      final jobs = await jobsRepository.getJobs(
        limit: event.limit,
        offset: event.offset,
      );
      emit(JobsListLoaded(jobs));
    } catch (e) {
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
      await jobsRepository.deleteJob(event.jobId);
      emit(JobDeleted(event.jobId));
    } catch (e) {
      emit(JobsError(message: e.toString()));
    }
  }

  Future<void> _onRefreshJobs(
    RefreshJobsEvent event,
    Emitter<JobsState> emit,
  ) async {
    try {
      final jobs = await jobsRepository.getJobs();
      emit(JobsListLoaded(jobs));
    } catch (e) {
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
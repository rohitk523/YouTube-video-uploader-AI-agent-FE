import 'package:equatable/equatable.dart';
import '../../../shared/models/job_models.dart';

abstract class JobsState extends Equatable {
  const JobsState();

  @override
  List<Object?> get props => [];
}

class JobsInitial extends JobsState {}

class JobsLoading extends JobsState {}

class JobsListLoaded extends JobsState {
  final List<JobListItem> jobs;

  const JobsListLoaded(this.jobs);

  @override
  List<Object> get props => [jobs];
}

class JobDetailsLoaded extends JobsState {
  final JobResponse job;

  const JobDetailsLoaded(this.job);

  @override
  List<Object> get props => [job];
}

class JobStatusUpdated extends JobsState {
  final JobStatusResponse status;

  const JobStatusUpdated(this.status);

  @override
  List<Object> get props => [status];
}

class JobCreated extends JobsState {
  final JobResponse job;

  const JobCreated(this.job);

  @override
  List<Object> get props => [job];
}

class JobDeleted extends JobsState {
  final String jobId;

  const JobDeleted(this.jobId);

  @override
  List<Object> get props => [jobId];
}

class JobDeletedAndListUpdated extends JobsState {
  final String deletedJobId;
  final List<JobListItem> updatedJobs;

  const JobDeletedAndListUpdated({
    required this.deletedJobId,
    required this.updatedJobs,
  });

  @override
  List<Object> get props => [deletedJobId, updatedJobs];
}

class JobsError extends JobsState {
  final String message;
  final String? errorCode;

  const JobsError({
    required this.message,
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, errorCode];
} 
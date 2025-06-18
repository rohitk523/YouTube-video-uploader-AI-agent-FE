import 'package:equatable/equatable.dart';
import '../../../shared/models/job_models.dart';

abstract class JobsEvent extends Equatable {
  const JobsEvent();

  @override
  List<Object?> get props => [];
}

class LoadJobsEvent extends JobsEvent {
  final int? limit;
  final int? offset;

  const LoadJobsEvent({this.limit, this.offset});

  @override
  List<Object?> get props => [limit, offset];
}

class LoadJobDetailsEvent extends JobsEvent {
  final String jobId;

  const LoadJobDetailsEvent(this.jobId);

  @override
  List<Object> get props => [jobId];
}

class RefreshJobStatusEvent extends JobsEvent {
  final String jobId;

  const RefreshJobStatusEvent(this.jobId);

  @override
  List<Object> get props => [jobId];
}

class CreateJobEvent extends JobsEvent {
  final CreateJobRequest request;

  const CreateJobEvent(this.request);

  @override
  List<Object> get props => [request];
}

class DeleteJobEvent extends JobsEvent {
  final String jobId;

  const DeleteJobEvent(this.jobId);

  @override
  List<Object> get props => [jobId];
}

class RefreshJobsEvent extends JobsEvent {}

class StartJobPollingEvent extends JobsEvent {
  final String jobId;

  const StartJobPollingEvent(this.jobId);

  @override
  List<Object> get props => [jobId];
}

class StopJobPollingEvent extends JobsEvent {} 
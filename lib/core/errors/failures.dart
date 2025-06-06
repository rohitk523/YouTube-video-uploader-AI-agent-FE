import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  
  const Failure(this.message);
  
  @override
  List<Object> get props => [message];
}

// Server Failures
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure(super.message);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(super.message);
}

class ForbiddenFailure extends Failure {
  const ForbiddenFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

class TooManyRequestsFailure extends Failure {
  const TooManyRequestsFailure(super.message);
}

// File Failures
class FileUploadFailure extends Failure {
  const FileUploadFailure(super.message);
}

class FileSizeExceededFailure extends Failure {
  const FileSizeExceededFailure(super.message);
}

class InvalidFileTypeFailure extends Failure {
  const InvalidFileTypeFailure(super.message);
}

class FileNotFoundFailure extends Failure {
  const FileNotFoundFailure(super.message);
}

// Validation Failures
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class InvalidInputFailure extends Failure {
  const InvalidInputFailure(super.message);
}

class RequiredFieldFailure extends Failure {
  const RequiredFieldFailure(super.message);
}

// YouTube Failures
class YouTubeUploadFailure extends Failure {
  const YouTubeUploadFailure(super.message);
}

class YouTubeAuthFailure extends Failure {
  const YouTubeAuthFailure(super.message);
}

class YouTubeQuotaExceededFailure extends Failure {
  const YouTubeQuotaExceededFailure(super.message);
}

// Job Failures
class JobCreationFailure extends Failure {
  const JobCreationFailure(super.message);
}

class JobNotFoundFailure extends Failure {
  const JobNotFoundFailure(super.message);
}

class JobProcessingFailure extends Failure {
  const JobProcessingFailure(super.message);
}

class JobCancelledFailure extends Failure {
  const JobCancelledFailure(super.message);
}

// Cache Failures
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

// Generic Failures
class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}

class ParseFailure extends Failure {
  const ParseFailure(super.message);
} 
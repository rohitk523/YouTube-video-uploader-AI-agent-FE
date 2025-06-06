class ServerException implements Exception {
  final String message;
  final int? statusCode;
  
  const ServerException(this.message, [this.statusCode]);
  
  @override
  String toString() => 'ServerException: $message (Status: $statusCode)';
}

class NetworkException implements Exception {
  final String message;
  
  const NetworkException(this.message);
  
  @override
  String toString() => 'NetworkException: $message';
}

class TimeoutException implements Exception {
  final String message;
  
  const TimeoutException(this.message);
  
  @override
  String toString() => 'TimeoutException: $message';
}

class UnauthorizedException implements Exception {
  final String message;
  
  const UnauthorizedException(this.message);
  
  @override
  String toString() => 'UnauthorizedException: $message';
}

class ForbiddenException implements Exception {
  final String message;
  
  const ForbiddenException(this.message);
  
  @override
  String toString() => 'ForbiddenException: $message';
}

class NotFoundException implements Exception {
  final String message;
  
  const NotFoundException(this.message);
  
  @override
  String toString() => 'NotFoundException: $message';
}

class TooManyRequestsException implements Exception {
  final String message;
  
  const TooManyRequestsException(this.message);
  
  @override
  String toString() => 'TooManyRequestsException: $message';
}

class FileUploadException implements Exception {
  final String message;
  
  const FileUploadException(this.message);
  
  @override
  String toString() => 'FileUploadException: $message';
}

class FileSizeExceededException implements Exception {
  final String message;
  final int maxSizeInMB;
  final int actualSizeInMB;
  
  const FileSizeExceededException(
    this.message,
    this.maxSizeInMB,
    this.actualSizeInMB,
  );
  
  @override
  String toString() => 'FileSizeExceededException: $message (Max: ${maxSizeInMB}MB, Actual: ${actualSizeInMB}MB)';
}

class InvalidFileTypeException implements Exception {
  final String message;
  final String actualType;
  final List<String> allowedTypes;
  
  const InvalidFileTypeException(
    this.message,
    this.actualType,
    this.allowedTypes,
  );
  
  @override
  String toString() => 'InvalidFileTypeException: $message (Actual: $actualType, Allowed: ${allowedTypes.join(', ')})';
}

class ValidationException implements Exception {
  final String message;
  final Map<String, String>? fieldErrors;
  
  const ValidationException(this.message, [this.fieldErrors]);
  
  @override
  String toString() {
    if (fieldErrors != null && fieldErrors!.isNotEmpty) {
      final errors = fieldErrors!.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');
      return 'ValidationException: $message (Errors: $errors)';
    }
    return 'ValidationException: $message';
  }
}

class YouTubeException implements Exception {
  final String message;
  final String? errorCode;
  
  const YouTubeException(this.message, [this.errorCode]);
  
  @override
  String toString() => 'YouTubeException: $message (Code: $errorCode)';
}

class JobException implements Exception {
  final String message;
  final String? jobId;
  final String? status;
  
  const JobException(this.message, [this.jobId, this.status]);
  
  @override
  String toString() => 'JobException: $message (JobId: $jobId, Status: $status)';
}

class CacheException implements Exception {
  final String message;
  
  const CacheException(this.message);
  
  @override
  String toString() => 'CacheException: $message';
}

class ParseException implements Exception {
  final String message;
  final Type? expectedType;
  
  const ParseException(this.message, [this.expectedType]);
  
  @override
  String toString() => 'ParseException: $message (Expected: $expectedType)';
} 
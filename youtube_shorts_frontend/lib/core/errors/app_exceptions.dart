abstract class AppException implements Exception {
  final String message;
  final int? statusCode;
  
  const AppException(this.message, [this.statusCode]);
  
  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException(String message) : super(message);
}

class BadRequestException extends AppException {
  const BadRequestException(String message) : super(message, 400);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException(String message) : super(message, 401);
}

class ForbiddenException extends AppException {
  const ForbiddenException(String message) : super(message, 403);
}

class NotFoundException extends AppException {
  const NotFoundException(String message) : super(message, 404);
}

class ConflictException extends AppException {
  const ConflictException(String message) : super(message, 409);
}

class ValidationException extends AppException {
  const ValidationException(String message) : super(message, 422);
}

class ServerException extends AppException {
  const ServerException(String message) : super(message, 500);
}

class CacheException extends AppException {
  const CacheException(String message) : super(message);
}

class StorageException extends AppException {
  const StorageException(String message) : super(message);
}

class GenericException extends AppException {
  const GenericException(String message) : super(message);
} 
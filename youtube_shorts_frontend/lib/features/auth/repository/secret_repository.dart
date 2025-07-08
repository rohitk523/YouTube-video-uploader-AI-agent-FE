import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../shared/models/secret_models.dart';

abstract class SecretRepository {
  Future<SecretValidationResponse> validateSecret(File jsonFile);
  Future<SecretUploadResponse> uploadSecret(File jsonFile);
  Future<SecretValidationResponse> validateSecretWeb(PlatformFile platformFile);
  Future<SecretUploadResponse> uploadSecretWeb(PlatformFile platformFile);
  Future<SecretStatusResponse> getSecretStatus();
  Future<List<SecretResponse>> getUserSecrets();
  Future<void> deleteSecret(String secretId);
  Future<SecretUploadResponse> reuploadSecret(File jsonFile);
}

class SecretRepositoryImpl implements SecretRepository {
  final ApiClient _apiClient;
  
  SecretRepositoryImpl(this._apiClient);
  
  @override
  Future<SecretValidationResponse> validateSecret(File jsonFile) async {
    try {
      // Create form data with the file
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          jsonFile.path,
          filename: jsonFile.path.split('/').last,
        ),
      });
      
      final response = await _apiClient.post(
        ApiConstants.secretsValidate,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      
      return SecretValidationResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  @override
  Future<SecretValidationResponse> validateSecretWeb(PlatformFile platformFile) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          platformFile.bytes!,
          filename: platformFile.name,
        ),
      });
      final response = await _apiClient.post(
        ApiConstants.secretsValidate,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      return SecretValidationResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  @override
  Future<SecretUploadResponse> uploadSecret(File jsonFile) async {
    try {
      // Create form data with the file
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          jsonFile.path,
          filename: jsonFile.path.split('/').last,
        ),
      });
      
      final response = await _apiClient.post(
        ApiConstants.secretsUpload,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      
      return SecretUploadResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  @override
  Future<SecretUploadResponse> uploadSecretWeb(PlatformFile platformFile) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          platformFile.bytes!,
          filename: platformFile.name,
        ),
      });
      final response = await _apiClient.post(
        ApiConstants.secretsUpload,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      return SecretUploadResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  @override
  Future<SecretStatusResponse> getSecretStatus() async {
    try {
      final response = await _apiClient.get(ApiConstants.secretsStatus);
      return SecretStatusResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  @override
  Future<List<SecretResponse>> getUserSecrets() async {
    try {
      final response = await _apiClient.get(ApiConstants.secretsList);
      final List<dynamic> secretsJson = response.data;
      return secretsJson.map((json) => SecretResponse.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  @override
  Future<void> deleteSecret(String secretId) async {
    try {
      await _apiClient.delete('${ApiConstants.secretsDelete}/$secretId');
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  @override
  Future<SecretUploadResponse> reuploadSecret(File jsonFile) async {
    try {
      // Create form data with the file
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          jsonFile.path,
          filename: jsonFile.path.split('/').last,
        ),
      });
      
      final response = await _apiClient.post(
        ApiConstants.secretsReupload,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      
      return SecretUploadResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  AppException _handleError(dynamic error) {
    if (error is AppException) return error;
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return NetworkException('Connection timeout. Please check your internet connection.');
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final message = error.response?.data?['detail'] ?? 'Server error occurred';
          if (statusCode == 400) {
            return ValidationException(message);
          } else if (statusCode == 401) {
            return UnauthorizedException('Authentication required');
          } else if (statusCode == 413) {
            return ValidationException('File too large. Maximum size is 1MB.');
          } else if (statusCode == 422) {
            return ValidationException('Invalid file format or content');
          }
          return ServerException(message);
        case DioExceptionType.cancel:
          return GenericException('Request was cancelled');
        case DioExceptionType.connectionError:
          return NetworkException('Unable to connect to server');
        default:
          return GenericException('Unexpected error occurred');
      }
    }
    return GenericException('Secret management error: ${error.toString()}');
  }
} 
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../errors/app_exceptions.dart';

class ApiClient {
  late final Dio _dio;
  static ApiClient? _instance;
  
  factory ApiClient() {
    _instance ??= ApiClient._internal();
    return _instance!;
  }
  
  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.apiBaseUrl,
      connectTimeout: ApiConstants.defaultTimeout,
      receiveTimeout: ApiConstants.defaultTimeout,
      sendTimeout: ApiConstants.uploadTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    _setupInterceptors();
  }
  
  void _setupInterceptors() {
    // Request interceptor for adding auth token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _getAccessToken();
        if (token != null && !options.path.contains('/oauth/token')) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Try to refresh token
          final refreshed = await _refreshToken();
          if (refreshed) {
            // Retry the original request
            final opts = error.requestOptions;
            final token = await _getAccessToken();
            if (token != null) {
              opts.headers['Authorization'] = 'Bearer $token';
            }
            try {
              final response = await _dio.fetch(opts);
              handler.resolve(response);
              return;
            } catch (e) {
              // If retry fails, proceed with original error
            }
          }
        }
        handler.next(error);
      },
    ));
    
    // Response interceptor for logging and error transformation
    _dio.interceptors.add(InterceptorsWrapper(
      onResponse: (response, handler) {
        print('Response [${response.statusCode}]: ${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (error, handler) {
        print('Error [${error.response?.statusCode}]: ${error.requestOptions.path}');
        final appException = _handleDioError(error);
        handler.reject(DioException(
          requestOptions: error.requestOptions,
          error: appException,
          type: error.type,
          response: error.response,
        ));
      },
    ));
  }
  
  // GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  // POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  // PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  // DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  // Upload file
  Future<Response<T>> uploadFile<T>(
    String path,
    File? file, {
    PlatformFile? platformFile,
    String fieldName = 'file',
    Map<String, dynamic>? additionalFields,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      MultipartFile multipartFile;
      
      if (kIsWeb && platformFile != null) {
        // For web, use PlatformFile bytes
        multipartFile = MultipartFile.fromBytes(
          platformFile.bytes!,
          filename: platformFile.name,
        );
      } else if (file != null) {
        // For mobile, use File
        final fileName = file.path.split('/').last;
        multipartFile = await MultipartFile.fromFile(file.path, filename: fileName);
      } else {
        throw GenericException('No file provided for upload');
      }
      
      final formData = FormData.fromMap({
        fieldName: multipartFile,
        ...?additionalFields,
      });
      
      return await _dio.post<T>(
        path,
        data: formData,
        onSendProgress: onSendProgress,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  // Download file
  Future<void> downloadFile(
    String path,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    void Function(int, int)? onReceiveProgress,
  }) async {
    try {
      await _dio.download(
        path,
        savePath,
        queryParameters: queryParameters,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  // Form data POST (for OAuth token endpoint)
  Future<Response<T>> postForm<T>(
    String path,
    Map<String, dynamic> data, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  // Token management
  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConstants.accessTokenKey);
  }
  
  Future<bool> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(ApiConstants.refreshTokenKey);
      
      if (refreshToken == null) return false;
      
      final response = await _dio.post(
        ApiConstants.refreshToken,
        data: json.encode({'refresh_token': refreshToken}),
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        await prefs.setString(ApiConstants.accessTokenKey, data['access_token']);
        if (data['refresh_token'] != null) {
          await prefs.setString(ApiConstants.refreshTokenKey, data['refresh_token']);
        }
        return true;
      }
    } catch (e) {
      print('Token refresh failed: $e');
    }
    return false;
  }
  
  AppException _handleError(dynamic error) {
    if (error is DioException) {
      return _handleDioError(error);
    }
    return GenericException('Unexpected error occurred: ${error.toString()}');
  }
  
  AppException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException('Connection timeout. Please check your internet connection.');
      
      case DioExceptionType.badResponse:
        return _handleResponseError(error);
      
      case DioExceptionType.cancel:
        return GenericException('Request was cancelled');
      
      case DioExceptionType.connectionError:
        return NetworkException('No internet connection');
      
      default:
        return GenericException('Unexpected error occurred');
    }
  }
  
  AppException _handleResponseError(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    
    String message = 'Unknown error occurred';
    
    if (data is Map<String, dynamic>) {
      message = data['detail'] ?? data['message'] ?? message;
    } else if (data is String) {
      message = data;
    }
    
    switch (statusCode) {
      case 400:
        return BadRequestException(message);
      case 401:
        return UnauthorizedException(message);
      case 403:
        return ForbiddenException(message);
      case 404:
        return NotFoundException(message);
      case 409:
        return ConflictException(message);
      case 422:
        return ValidationException(message);
      case 500:
        return ServerException('Internal server error');
      case 502:
      case 503:
      case 504:
        return ServerException('Server is temporarily unavailable');
      default:
        return GenericException('HTTP Error $statusCode: $message');
    }
  }
} 
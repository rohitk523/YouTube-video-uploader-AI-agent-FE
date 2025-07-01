import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../config/environment.dart';
import '../errors/app_exceptions.dart';

class ApiClient {
  late Dio _dio;
  static ApiClient? _instance;
  String _currentBaseUrl = '';
  bool _isUsingFallback = false;
  
  factory ApiClient() {
    _instance ??= ApiClient._internal();
    return _instance!;
  }
  
  ApiClient._internal() {
    print('🚀 Initializing API Client');
    print('📍 Environment: ${EnvironmentConfig.currentEnvironment}');
    print('🌐 Primary URL: ${EnvironmentConfig.apiBaseUrl}');
    print('🔄 Fallback URL: ${EnvironmentConfig.fallbackApiBaseUrl}');
    _initializeDio();
  }
  
  void _initializeDio([String? baseUrl]) {
    _currentBaseUrl = baseUrl ?? ApiConstants.apiBaseUrl;
    print('🔧 Initializing Dio with base URL: $_currentBaseUrl');
    _dio = Dio(BaseOptions(
      baseUrl: _currentBaseUrl, // ApiConstants.apiBaseUrl already includes /api/v1
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
        print('🌐 API Request: ${_dio.options.baseUrl}${options.path}');
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
        print('✅ Response [${response.statusCode}]: ${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (error, handler) {
        print('❌ Error [${error.response?.statusCode}]: ${error.requestOptions.path}');
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
  
  // Enhanced request method with automatic failover
  Future<Response<T>> _requestWithFailover<T>(
    Future<Response<T>> Function() requestFunction,
  ) async {
    try {
      // Try with current base URL (Railway)
      return await requestFunction();
    } catch (error) {
      // If it's a network error and we're in production and not already using fallback
      if (_shouldTryFailover(error)) {
        print('🔄 Primary API failed, trying fallback URL...');
        
        // Switch to fallback URL (Render)  
        final fallbackUrl = '${EnvironmentConfig.fallbackApiBaseUrl}/api/v1';
        _initializeDio(fallbackUrl);
        _isUsingFallback = true;
        
        try {
          final result = await requestFunction();
          print('✅ Fallback API successful');
          return result;
        } catch (fallbackError) {
          print('❌ Fallback API also failed');
          // Reset to original URL for next attempt
          _initializeDio();
          _isUsingFallback = false;
          throw _handleError(fallbackError);
        }
      }
      throw _handleError(error);
    }
  }
  
  bool _shouldTryFailover(dynamic error) {
    // Only try failover in production and if not already using fallback
    if (!EnvironmentConfig.isProduction || _isUsingFallback) {
      return false;
    }
    
    // Try failover for network errors or server errors (5xx)
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return true;
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          return statusCode != null && statusCode >= 500;
        default:
          return false;
      }
    }
    return false;
  }

  // GET request with failover
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _requestWithFailover<T>(() async {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    });
  }
  
  // POST request with failover
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _requestWithFailover<T>(() async {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    });
  }
  
  // PUT request with failover
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _requestWithFailover<T>(() async {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    });
  }
  
  // DELETE request with failover
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _requestWithFailover<T>(() async {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    });
  }
  
  // Upload file with failover
  Future<Response<T>> uploadFile<T>(
    String path,
    File? file, {
    PlatformFile? platformFile,
    String fieldName = 'file',
    Map<String, dynamic>? additionalFields,
    void Function(int, int)? onSendProgress,
  }) async {
    return await _requestWithFailover<T>(() async {
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
    });
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
  
  // Form data POST (for OAuth token endpoint) with failover
  Future<Response<T>> postForm<T>(
    String path,
    Map<String, dynamic> data, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return await _requestWithFailover<T>(() async {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );
    });
  }
  
  // Get current API status
  String get currentApiUrl => _currentBaseUrl;
  bool get isUsingFallback => _isUsingFallback;
  
  // Method to manually reset to primary URL
  void resetToPrimary() {
    if (_isUsingFallback) {
      _initializeDio();
      _isUsingFallback = false;
      print('🔄 Reset to primary API URL');
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
import 'dart:async';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

enum HealthStatus {
  unknown,
  checking,
  healthy,
  unhealthy,
}

class HealthService {
  final ApiClient _apiClient = ApiClient();
  
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();
  
  /// Performs a health check on the backend server
  /// Returns true if the server is healthy, false otherwise
  Future<bool> checkHealth({Duration timeout = const Duration(seconds: 30)}) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.healthEndpoint,
        options: Options(
          receiveTimeout: timeout,
          sendTimeout: timeout,
        ),
      );
      
      // Consider healthy if status code is 200-299
      return response.statusCode != null && 
             response.statusCode! >= 200 && 
             response.statusCode! < 300;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }
  
  /// Performs a health check with detailed status information
  Future<Map<String, dynamic>> checkHealthDetailed({Duration timeout = const Duration(seconds: 30)}) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.healthEndpoint,
        options: Options(
          receiveTimeout: timeout,
          sendTimeout: timeout,
        ),
      );
      
      final isHealthy = response.statusCode != null && 
                        response.statusCode! >= 200 && 
                        response.statusCode! < 300;
      
      return {
        'isHealthy': isHealthy,
        'statusCode': response.statusCode,
        'data': response.data,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'isHealthy': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
} 
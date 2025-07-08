import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../shared/models/upload_models.dart';

abstract class UploadRepository {
  Future<UploadConfigResponse> checkConfig();
  Future<UploadResponse> uploadVideo(
    File? videoFile, {
    required String title,
    required String description,
    String? customName,
    PlatformFile? platformFile,
    bool isTemp = true,
    void Function(double)? onProgress,
  });
  Future<UploadResponse> uploadTranscriptText(
    String transcriptText, {
    required String title,
    String? customName,
  });
  Future<UploadResponse> uploadTranscriptFile(
    File? transcriptFile, {
    required String title,
    String? customName,
    PlatformFile? platformFile,
    void Function(double)? onProgress,
  });
  Future<UploadResponse> getUploadDetails(String uploadId);
  Future<void> downloadUpload(String uploadId, String savePath);
  Future<void> deleteUpload(String uploadId);
}

class UploadRepositoryImpl implements UploadRepository {
  final ApiClient _apiClient;
  
  UploadRepositoryImpl(this._apiClient);
  
  @override
  Future<UploadConfigResponse> checkConfig() async {
    try {
      final response = await _apiClient.get(ApiConstants.uploadConfig);
      return UploadConfigResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  @override
  Future<UploadResponse> uploadVideo(
    File? videoFile, {
    required String title,
    required String description,
    String? customName,
    PlatformFile? platformFile,
    bool isTemp = true,
    void Function(double)? onProgress,
  }) async {
    try {
      final queryParams = <String, String>{
        'is_temp': isTemp.toString(),
      };
      
      if (customName != null && customName.isNotEmpty) {
        queryParams['custom_name'] = customName;
      }

      final response = await _apiClient.uploadFile(
        ApiConstants.uploadVideo,
        videoFile,
        platformFile: platformFile,
        queryParameters: queryParams,
        additionalFields: {
          'title': title,
          'description': description,
        },
        onSendProgress: onProgress != null 
          ? (sent, total) => onProgress(sent / total) 
          : null,
      );
      
      return UploadResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  @override
  Future<UploadResponse> uploadTranscriptText(
    String transcriptText, {
    required String title,
    String? customName,
  }) async {
    try {
      final request = TranscriptUploadRequest(
        content: transcriptText,
        isTemp: true,
      );
      
      final queryParams = <String, String>{
        'is_temp': 'true',
      };
      
      if (customName != null && customName.isNotEmpty) {
        queryParams['custom_name'] = customName;
      }
      
      final response = await _apiClient.post(
        ApiConstants.uploadTranscriptText,
        data: json.encode({
          ...request.toJson(),
          'title': title,
        }),
        queryParameters: queryParams,
      );
      
      return UploadResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  @override
  Future<UploadResponse> uploadTranscriptFile(
    File? transcriptFile, {
    required String title,
    String? customName,
    PlatformFile? platformFile,
    void Function(double)? onProgress,
  }) async {
    try {
      final queryParams = <String, String>{
        'is_temp': 'true',
      };
      
      if (customName != null && customName.isNotEmpty) {
        queryParams['custom_name'] = customName;
      }

      final response = await _apiClient.uploadFile(
        ApiConstants.uploadTranscriptFile,
        transcriptFile,
        platformFile: platformFile,
        queryParameters: queryParams,
        additionalFields: {
          'title': title,
        },
        onSendProgress: onProgress != null 
          ? (sent, total) => onProgress(sent / total) 
          : null,
      );
      
      return UploadResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  @override
  Future<UploadResponse> getUploadDetails(String uploadId) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.getUploadDetails(uploadId),
      );
      
      return UploadResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  @override
  Future<void> downloadUpload(String uploadId, String savePath) async {
    try {
      await _apiClient.downloadFile(
        ApiConstants.downloadUpload(uploadId),
        savePath,
        queryParameters: {
          'use_presigned': 'true',
        },
      );
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  @override
  Future<void> deleteUpload(String uploadId) async {
    try {
      await _apiClient.delete(ApiConstants.deleteUpload(uploadId));
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  AppException _handleError(dynamic error) {
    if (error is AppException) return error;
    return GenericException('Upload error: ${error.toString()}');
  }
} 
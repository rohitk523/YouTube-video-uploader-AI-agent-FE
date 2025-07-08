import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../shared/models/job_models.dart';

abstract class JobsRepository {
  Future<JobResponse> createJob(CreateJobRequest request);
  Future<JobResponse> createJobWithStructure(CreateJobWithStructureRequest request);
  Future<UserJobsWithFilesResponse> getUserJobsWithFiles({int page = 1, int pageSize = 10});
  Future<MoveTempFilesResponse> moveTempFilesToJob(
    String jobId, {
    String? videoUploadId,
    String? transcriptUploadId,
    String? customVideoName,
    String? customTranscriptName,
  });
  Future<JobResponse> getJobDetails(String jobId);
  Future<JobStatusResponse> getJobStatus(String jobId);
  Future<List<JobListItem>> getJobs({
    int? limit,
    int? offset,
  });
  Future<void> deleteJob(String jobId);
  Future<VoicesResponse> getVoices();
  Future<void> downloadProcessedVideo(String jobId, String savePath);
  Future<Map<String, dynamic>> uploadToYoutube(String jobId);
}

class JobsRepositoryImpl implements JobsRepository {
  final ApiClient _apiClient;
  
  JobsRepositoryImpl(this._apiClient);
  
  @override
  Future<JobResponse> createJob(CreateJobRequest request) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.createJob,
        data: json.encode(request.toJson()),
      );
      
      return JobResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  @override
  Future<JobResponse> createJobWithStructure(CreateJobWithStructureRequest request) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.createJobWithStructure,
        data: json.encode(request.toJson()),
      );
      
      return JobResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  @override
  Future<UserJobsWithFilesResponse> getUserJobsWithFiles({int page = 1, int pageSize = 10}) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };
      
      final response = await _apiClient.get(
        ApiConstants.userJobsWithFiles,
        queryParameters: queryParameters,
      );
      
      return UserJobsWithFilesResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  @override
  Future<MoveTempFilesResponse> moveTempFilesToJob(
    String jobId, {
    String? videoUploadId,
    String? transcriptUploadId,
    String? customVideoName,
    String? customTranscriptName,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};
      
      if (videoUploadId != null) {
        queryParameters['videoUploadId'] = videoUploadId;
      }
      
      if (transcriptUploadId != null) {
        queryParameters['transcriptUploadId'] = transcriptUploadId;
      }
      
      if (customVideoName != null) {
        queryParameters['customVideoName'] = customVideoName;
      }
      
      if (customTranscriptName != null) {
        queryParameters['customTranscriptName'] = customTranscriptName;
      }
      
      final response = await _apiClient.post(
        ApiConstants.moveTempFilesToJob(jobId),
        queryParameters: queryParameters,
      );
      
      return MoveTempFilesResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  @override
  Future<JobResponse> getJobDetails(String jobId) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.getJob(jobId),
      );
      
      return JobResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  @override
  Future<JobStatusResponse> getJobStatus(String jobId) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.getJobStatus(jobId),
      );
      
      return JobStatusResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  @override
  Future<List<JobListItem>> getJobs({
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};
      
      if (limit != null) {
        queryParameters['limit'] = limit.toString();
      }
      
      if (offset != null) {
        queryParameters['offset'] = offset.toString();
      }
      
      final response = await _apiClient.get(
        ApiConstants.listJobs,
        queryParameters: queryParameters,
      );
      
      // Backend returns wrapped response: { "jobs": [...], "total": 25, ... }
      final responseData = response.data as Map<String, dynamic>;
      final jobsList = responseData['jobs'] as List<dynamic>;
      return jobsList.map((job) => JobListItem.fromJson(job)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  @override
  Future<void> deleteJob(String jobId) async {
    try {
      await _apiClient.delete(ApiConstants.deleteJob(jobId));
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  @override
  Future<VoicesResponse> getVoices() async {
    try {
      final response = await _apiClient.get(ApiConstants.voices);
      return VoicesResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  @override
  Future<void> downloadProcessedVideo(String jobId, String savePath) async {
    try {
      await _apiClient.downloadFile(
        ApiConstants.downloadProcessedVideo(jobId),
        savePath,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  @override
  Future<Map<String, dynamic>> uploadToYoutube(String jobId) async {
    try {
      final request = YouTubeUploadRequest(jobId: jobId);
      final response = await _apiClient.post(
        ApiConstants.uploadToYoutube,
        data: json.encode(request.toJson()),
      );
      
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  AppException _handleError(dynamic error) {
    if (error is AppException) return error;
    return GenericException('Jobs error: ${error.toString()}');
  }
} 
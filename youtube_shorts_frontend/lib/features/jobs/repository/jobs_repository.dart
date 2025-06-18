import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../shared/models/job_models.dart';

abstract class JobsRepository {
  Future<JobResponse> createJob(CreateJobRequest request);
  Future<JobResponse> getJobDetails(String jobId);
  Future<JobStatusResponse> getJobStatus(String jobId);
  Future<List<JobResponse>> getJobs({
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
  Future<List<JobResponse>> getJobs({
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
      
      // Expect response to be a list of jobs
      final jobsList = response.data as List<dynamic>;
      return jobsList.map((job) => JobResponse.fromJson(job)).toList();
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
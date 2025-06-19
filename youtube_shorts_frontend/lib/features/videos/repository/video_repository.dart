import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/video_models.dart';

class VideoRepository {
  final ApiClient _apiClient;

  VideoRepository(this._apiClient);

  /// Get list of videos from S3 bucket
  Future<S3VideoListResponse> getS3Videos({
    int page = 1,
    int pageSize = 10,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final response = await _apiClient.get(
        '${ApiConstants.videosEndpoint}/s3-videos',
        queryParameters: queryParams,
      );

      return S3VideoListResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch S3 videos: $e');
    }
  }

  /// Get recent videos (top 5 for quick selection)
  Future<List<S3VideoModel>> getRecentVideos({int limit = 5}) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.videosEndpoint}/s3-videos/recent',
        queryParameters: {'limit': limit},
      );

      final responseData = response.data as Map<String, dynamic>;
      final videosList = responseData['videos'] as List;
      return videosList
          .map((video) => S3VideoModel.fromJson(video as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch recent videos: $e');
    }
  }

  /// Get video metadata by S3 key
  Future<S3VideoModel> getVideoByS3Key(String s3Key) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.videosEndpoint}/s3-videos/by-key/$s3Key',
      );

      return S3VideoModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch video by S3 key: $e');
    }
  }
} 
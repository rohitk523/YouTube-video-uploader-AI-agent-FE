class ApiConstants {
  // Base URLs
  static const String developmentBaseUrl = 'http://localhost:8000';
  static const String productionBaseUrl = 'https://your-production-domain.com';
  
  // Use development URL by default - change for production
  static const String baseUrl = developmentBaseUrl;
  static const String apiVersion = 'v1';
  static String get apiBaseUrl => '$baseUrl/api/$apiVersion';
  
  // Authentication endpoints
  static const String register = '/oauth/register';
  static const String token = '/oauth/token';
  static const String refreshToken = '/oauth/token/refresh';
  static const String userInfo = '/oauth/userinfo';
  static const String updateProfile = '/oauth/profile';
  static const String changePassword = '/oauth/change-password';
  static const String logout = '/oauth/logout';
  
  // Upload endpoints
  static const String uploadConfig = '/upload/config/check';
  static const String uploadVideo = '/upload/video';
  static const String uploadTranscriptText = '/upload/transcript-text';
  static const String uploadTranscriptFile = '/upload/transcript-file';
  static String getUploadDetails(String uploadId) => '/upload/$uploadId';
  static String downloadUpload(String uploadId) => '/upload/$uploadId/download';
  static String deleteUpload(String uploadId) => '/upload/$uploadId';
  
  // Job endpoints
  static const String createJob = '/jobs/create';
  static const String listJobs = '/jobs';
  static String getJob(String jobId) => '/jobs/$jobId';
  static String getJobStatus(String jobId) => '/jobs/$jobId/status';
  static String deleteJob(String jobId) => '/jobs/$jobId';
  
  // YouTube endpoints
  static const String voices = '/youtube/voices';
  static const String youtubeInfo = '/youtube/info';
  static String downloadProcessedVideo(String jobId) => '/youtube/download/$jobId';
  static const String uploadToYoutube = '/youtube/upload-from-job';
  
  // Request timeouts
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 5);
  
  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  
  // OAuth scopes
  static const String defaultScopes = 'read write upload youtube';
} 
import '../config/environment.dart';

class ApiConstants {
  // Base URLs
  static String get baseUrl => EnvironmentConfig.apiBaseUrl;
  
  static const String apiVersion = 'v1';
  static String get apiBaseUrl => '$baseUrl/api/$apiVersion';
  
  // Authentication endpoints
  static const String authEndpoint = '/oauth';
  static const String loginEndpoint = '$authEndpoint/token';
  static const String registerEndpoint = '$authEndpoint/register';
  static const String refreshEndpoint = '$authEndpoint/token/refresh';
  static const String userInfoEndpoint = '$authEndpoint/userinfo';
  static const String logoutEndpoint = '$authEndpoint/logout';
  
  // Legacy auth endpoint names (for backward compatibility)
  static const String register = registerEndpoint;
  static const String token = loginEndpoint;
  static const String refreshToken = refreshEndpoint;
  static const String userInfo = userInfoEndpoint;
  static const String updateProfile = '$authEndpoint/profile';
  static const String changePassword = '$authEndpoint/change-password';
  static const String logout = logoutEndpoint;
  
  // Upload endpoints
  static const String uploadEndpoint = '/upload';
  static const String videoUploadEndpoint = '$uploadEndpoint/video';
  static const String transcriptUploadEndpoint = '$uploadEndpoint/transcript-text';
  
  // Legacy upload endpoint names
  static const String uploadConfig = '$uploadEndpoint/config/check';
  static const String uploadVideo = videoUploadEndpoint;
  static const String uploadTranscriptText = transcriptUploadEndpoint;
  static const String uploadTranscriptFile = '$uploadEndpoint/transcript-file';
  
  // Upload helper methods
  static String getUploadDetails(String uploadId) => '$uploadEndpoint/$uploadId';
  static String downloadUpload(String uploadId) => '$uploadEndpoint/$uploadId/download';
  static String deleteUpload(String uploadId) => '$uploadEndpoint/$uploadId';
  
  // Jobs endpoints
  static const String jobsEndpoint = '/jobs';
  static const String createJobEndpoint = '$jobsEndpoint/create';
  
  // Legacy job endpoint names
  static const String createJob = createJobEndpoint;
  static const String listJobs = jobsEndpoint;
  
  // Job helper methods
  static String getJob(String jobId) => '$jobsEndpoint/$jobId';
  static String getJobStatus(String jobId) => '$jobsEndpoint/$jobId/status';
  static String deleteJob(String jobId) => '$jobsEndpoint/$jobId';
  static String downloadJobVideo(String jobId) => '$jobsEndpoint/$jobId/download';
  
  // YouTube endpoints
  static const String youtubeEndpoint = '/youtube';
  static const String downloadEndpoint = '$youtubeEndpoint/download';
  static const String uploadToYoutubeEndpoint = '$youtubeEndpoint/upload-from-job';
  
  // Legacy YouTube endpoint names
  static const String voices = '$youtubeEndpoint/voices';
  static const String youtubeInfo = '$youtubeEndpoint/info';
  static const String uploadToYoutube = uploadToYoutubeEndpoint;
  
  // YouTube helper methods
  static String downloadProcessedVideo(String jobId) => '$youtubeEndpoint/download/$jobId';
  
  // Videos endpoints (NEW)
  static const String videosEndpoint = '/videos';
  
  // Secrets endpoints (NEW)
  static const String secretsEndpoint = '/secrets';
  static const String secretsValidate = '$secretsEndpoint/validate';
  static const String secretsUpload = '$secretsEndpoint/upload';
  static const String secretsStatus = '$secretsEndpoint/status';
  static const String secretsList = '$secretsEndpoint/list';
  static const String secretsDelete = '$secretsEndpoint';
  static const String secretsReupload = '$secretsEndpoint/reupload';
  
  // System endpoints
  static const String healthEndpoint = '/health';
  static const String infoEndpoint = '/info';
  
  // File size limits
  static const int maxVideoSizeMB = 100;
  static const int maxTranscriptSizeMB = 10;
  
  // Supported formats
  static const List<String> supportedVideoFormats = ['mp4', 'mov', 'avi', 'mkv'];
  static const List<String> supportedTranscriptFormats = ['txt', 'srt'];
  
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
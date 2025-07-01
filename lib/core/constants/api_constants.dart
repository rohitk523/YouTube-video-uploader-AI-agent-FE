class ApiConstants {
  // Base URLs - Updated for Railway (primary) and Render (fallback)
  static const String baseUrl = 'https://youtube-shorts-api-production.up.railway.app/api/v1';
  static const String fallbackUrl = 'https://youtube-video-uploader-ai-agent-be.onrender.com/api/v1';
  static const String localBaseUrl = 'http://localhost:8000/api/v1';
  
  // Endpoints
  static const String uploadVideo = '/upload/video';
  static const String uploadTranscript = '/upload/transcript';
  static const String createJob = '/jobs/create';
  static const String getJobStatus = '/jobs/{id}/status';
  static const String getUserJobs = '/jobs/user';
  static const String deleteJob = '/jobs/{id}';
  static const String getVoices = '/voices';
  
  // YouTube API
  static const String youtubeUpload = '/youtube/upload';
  static const String youtubeStatus = '/youtube/status/{id}';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 60);
  
  // File upload limits
  static const int maxVideoSizeMB = 100;
  static const int maxTranscriptLength = 10000;
  
  // Polling intervals
  static const Duration jobStatusPollingInterval = Duration(seconds: 2);
  static const Duration longPollingInterval = Duration(seconds: 5);
} 
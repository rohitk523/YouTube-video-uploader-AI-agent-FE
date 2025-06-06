class AppConstants {
  // App Info
  static const String appName = 'YouTube Shorts Creator';
  static const String appVersion = '1.0.0';
  
  // Routes
  static const String splashRoute = '/';
  static const String uploadRoute = '/upload';
  static const String createShortRoute = '/create-short';
  static const String jobStatusRoute = '/job-status';
  static const String jobsListRoute = '/jobs';
  static const String settingsRoute = '/settings';
  
  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userPrefsKey = 'user_preferences';
  static const String recentJobsKey = 'recent_jobs';
  static const String appThemeKey = 'app_theme';
  
  // File Types
  static const List<String> supportedVideoExtensions = ['mp4', 'mov', 'avi'];
  static const List<String> supportedTranscriptExtensions = ['txt', 'md'];
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultBorderRadius = 8.0;
  static const double cardElevation = 4.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 300);
  static const Duration mediumAnimation = Duration(milliseconds: 500);
  static const Duration longAnimation = Duration(milliseconds: 800);
  
  // Voice Options
  static const Map<String, String> voices = {
    'alloy': 'Neutral, balanced',
    'echo': 'Male voice',
    'fable': 'British accent',
    'onyx': 'Deep male voice',
    'nova': 'Female voice',
    'shimmer': 'Soft female voice',
  };
  
  // Privacy Settings
  static const List<String> privacyOptions = ['public', 'unlisted', 'private'];
  
  // Error Messages
  static const String genericErrorMessage = 'Something went wrong. Please try again.';
  static const String networkErrorMessage = 'Please check your internet connection.';
  static const String fileUploadErrorMessage = 'Failed to upload file. Please try again.';
  static const String jobCreationErrorMessage = 'Failed to create job. Please try again.';
} 
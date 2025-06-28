enum Environment {
  development,
  production,
}

class EnvironmentConfig {
  static const String _environment = String.fromEnvironment(
    'FLUTTER_ENV',
    defaultValue: 'development',
  );
  
  static const String _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  
  static Environment get currentEnvironment {
    switch (_environment.toLowerCase()) {
      case 'production':
      case 'prod':
        return Environment.production;
      case 'development':
      case 'dev':
      default:
        return Environment.development;
    }
  }
  
  static String get apiBaseUrl {
    // If API_BASE_URL is explicitly provided, use it
    if (_apiBaseUrl.isNotEmpty) {
      return _apiBaseUrl;
    }
    
    // Otherwise, use environment-based defaults
    switch (currentEnvironment) {
      case Environment.production:
        return 'https://your-backend-domain.com'; // Replace with your actual backend URL
      case Environment.development:
        return 'http://localhost:8000';
    }
  }
  
  static bool get isProduction => currentEnvironment == Environment.production;
  static bool get isDevelopment => currentEnvironment == Environment.development;
  
  static String get environmentName => _environment;
  
  // Debug information
  static Map<String, dynamic> get debugInfo => {
    'environment': environmentName,
    'apiBaseUrl': apiBaseUrl,
    'isProduction': isProduction,
    'isDevelopment': isDevelopment,
  };
} 
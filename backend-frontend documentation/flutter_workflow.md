# Flutter Integration Workflow Guide

## Complete User Journey Workflow

This document outlines the complete workflow for integrating your Flutter app with the YouTube Shorts Creator API, showing the exact sequence of API calls needed for each user journey.

## 1. User Authentication Flow

### Registration and Login Sequence

```
1. User Registration:
   App → POST /api/v1/oauth/register
   ← 201 Created + access_token + user_profile

2. User Login:
   App → POST /api/v1/oauth/token (form-data)
   ← 200 OK + access_token + refresh_token

3. Get User Profile:
   App → GET /api/v1/oauth/userinfo (Bearer token)
   ← 200 OK + user_profile

4. Token Refresh (when needed):
   App → POST /api/v1/oauth/token/refresh
   ← 200 OK + new_access_token + new_refresh_token
```

## 2. Video Creation Workflow

### Complete Video Processing Sequence

```
1. Upload Video File:
   App → POST /api/v1/upload/video (multipart)
   ← 200 OK + video_upload_id

2. Upload Transcript:
   App → POST /api/v1/upload/transcript-text
   ← 200 OK + transcript_upload_id

3. Create Processing Job:
   App → POST /api/v1/jobs/create
   ← 200 OK + job_id + status: processing

4. Poll Job Status (every 5 seconds):
   App → GET /api/v1/jobs/{job_id}/status
   ← 200 OK + progress + status

5. Download Processed Video (when completed):
   App → GET /api/v1/youtube/download/{job_id}
   ← File download

6. Upload to YouTube:
   App → POST /api/v1/youtube/upload-from-job
   ← 200 OK + youtube_url + video_id
```

## 3. Flutter Implementation Guide

### Project Setup

Add these dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  shared_preferences: ^2.2.2
  file_picker: ^6.1.1
  video_player: ^2.8.1
  provider: ^6.1.1
  json_annotation: ^4.8.1

dev_dependencies:
  build_runner: ^2.4.7
  json_serializable: ^6.7.1
```

### API Service Structure

```dart
// lib/services/api_service.dart
class ApiService {
  static const String baseUrl = 'http://localhost:8000'; // Change for production
  static const String apiVersion = 'v1';
  
  static String get apiBaseUrl => '$baseUrl/api/$apiVersion';
  
  // HTTP client with error handling
  static Future<http.Response> makeRequest(
    String method,
    String endpoint, {
    Map<String, String>? headers,
    dynamic body,
    String? token,
  }) async {
    final uri = Uri.parse('$apiBaseUrl$endpoint');
    final defaultHeaders = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    
    final mergedHeaders = {...defaultHeaders, ...?headers};
    
    http.Response response;
    
    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(uri, headers: mergedHeaders);
        break;
      case 'POST':
        response = await http.post(uri, headers: mergedHeaders, body: body);
        break;
      case 'PUT':
        response = await http.put(uri, headers: mergedHeaders, body: body);
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: mergedHeaders);
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
    
    // Handle common errors
    if (response.statusCode >= 400) {
      final errorData = json.decode(response.body);
      throw ApiException(
        statusCode: response.statusCode,
        message: errorData['detail'] ?? 'Unknown error',
      );
    }
    
    return response;
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  
  ApiException({required this.statusCode, required this.message});
  
  @override
  String toString() => 'ApiException($statusCode): $message';
}
```

### Authentication Service

```dart
// lib/services/auth_service.dart
class AuthService {
  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  
  // Login with email and password
  static Future<AuthResponse> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${ApiService.apiBaseUrl}/oauth/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'password',
        'username': email,
        'password': password,
        'scope': 'read write upload youtube',
      },
    );
    
    if (response.statusCode == 200) {
      final authResponse = AuthResponse.fromJson(json.decode(response.body));
      
      // Store tokens securely
      await _storeTokens(authResponse.accessToken, authResponse.refreshToken);
      
      return authResponse;
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Login failed: ${response.body}',
      );
    }
  }
  
  // Register new user
  static Future<AuthResponse> register(UserRegisterRequest request) async {
    final response = await ApiService.makeRequest(
      'POST',
      '/oauth/register',
      body: json.encode(request.toJson()),
    );
    
    final authResponse = AuthResponse.fromJson(json.decode(response.body));
    
    // Store tokens and user data
    await _storeTokens(authResponse.accessToken, authResponse.refreshToken);
    if (authResponse.user != null) {
      await _storeUserData(authResponse.user!);
    }
    
    return authResponse;
  }
  
  // Get user profile
  static Future<UserProfile> getUserProfile(String token) async {
    final response = await ApiService.makeRequest(
      'GET',
      '/oauth/userinfo',
      token: token,
    );
    
    return UserProfile.fromJson(json.decode(response.body));
  }
  
  // Refresh access token
  static Future<AuthResponse> refreshToken() async {
    final refreshToken = await _getStoredRefreshToken();
    if (refreshToken == null) {
      throw Exception('No refresh token available');
    }
    
    final response = await ApiService.makeRequest(
      'POST',
      '/oauth/token/refresh',
      body: json.encode({'refresh_token': refreshToken}),
    );
    
    final authResponse = AuthResponse.fromJson(json.decode(response.body));
    await _storeTokens(authResponse.accessToken, authResponse.refreshToken);
    
    return authResponse;
  }
  
  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await _getStoredToken();
    return token != null && !_isTokenExpired(token);
  }
  
  // Get stored access token
  static Future<String?> getStoredToken() async {
    return await _getStoredToken();
  }
  
  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);
  }
  
  // Private helper methods
  static Future<void> _storeTokens(String accessToken, String? refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, accessToken);
    if (refreshToken != null) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
  }
  
  static Future<String?> _getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
  
  static Future<String?> _getStoredRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }
  
  static Future<void> _storeUserData(UserProfile user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));
  }
  
  static bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final exp = payload['exp'] as int;
      return DateTime.now().millisecondsSinceEpoch / 1000 >= exp;
    } catch (e) {
      return true; // Assume expired if we can't parse
    }
  }
}
```

### Upload Service

```dart
// lib/services/upload_service.dart
class UploadService {
  // Upload video file
  static Future<UploadResponse> uploadVideo(File videoFile) async {
    final token = await AuthService.getStoredToken();
    if (token == null) throw Exception('Not authenticated');
    
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiService.apiBaseUrl}/upload/video'),
    );
    
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', videoFile.path));
    request.fields['is_temp'] = 'true';
    
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      return UploadResponse.fromJson(json.decode(response.body));
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Upload failed: ${response.body}',
      );
    }
  }
  
  // Upload transcript text
  static Future<UploadResponse> uploadTranscript(String content) async {
    final token = await AuthService.getStoredToken();
    if (token == null) throw Exception('Not authenticated');
    
    final response = await ApiService.makeRequest(
      'POST',
      '/upload/transcript-text',
      token: token,
      body: json.encode({'content': content}),
    );
    
    return UploadResponse.fromJson(json.decode(response.body));
  }
}
```

## 4. Data Models Example

```dart
// lib/models/auth_models.dart
import 'package:json_annotation/json_annotation.dart';

part 'auth_models.g.dart';

@JsonSerializable()
class AuthResponse {
  @JsonKey(name: 'access_token')
  final String accessToken;
  
  @JsonKey(name: 'token_type')
  final String tokenType;
  
  @JsonKey(name: 'expires_in')
  final int expiresIn;
  
  @JsonKey(name: 'refresh_token')
  final String? refreshToken;
  
  final UserProfile? user;
  
  AuthResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    this.refreshToken,
    this.user,
  });
  
  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
  
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

@JsonSerializable()
class UserProfile {
  final String id;
  final String email;
  final String? username;
  
  @JsonKey(name: 'first_name')
  final String? firstName;
  
  @JsonKey(name: 'last_name')
  final String? lastName;
  
  @JsonKey(name: 'is_active')
  final bool isActive;
  
  @JsonKey(name: 'is_verified')
  final bool isVerified;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  
  UserProfile({
    required this.id,
    required this.email,
    this.username,
    this.firstName,
    this.lastName,
    required this.isActive,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
  
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);
}
```

## 5. Complete UI Example

```dart
// lib/screens/video_creation_screen.dart
class VideoCreationScreen extends StatefulWidget {
  @override
  _VideoCreationScreenState createState() => _VideoCreationScreenState();
}

class _VideoCreationScreenState extends State<VideoCreationScreen> {
  File? _selectedVideo;
  String _transcript = '';
  String _title = '';
  String _description = '';
  String _selectedVoice = 'alloy';
  List<String> _tags = [];
  
  bool _isUploading = false;
  bool _isProcessing = false;
  String? _currentJobId;
  JobStatus? _jobStatus;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create YouTube Short')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Video selection
            _buildVideoSelector(),
            SizedBox(height: 16),
            
            // Transcript input
            _buildTranscriptInput(),
            SizedBox(height: 16),
            
            // Video details
            _buildVideoDetails(),
            SizedBox(height: 16),
            
            // Voice selection
            _buildVoiceSelector(),
            SizedBox(height: 24),
            
            // Create button
            _buildCreateButton(),
            
            // Progress indicators
            if (_isUploading || _isProcessing) _buildProgressIndicator(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVideoSelector() {
    return Card(
      child: ListTile(
        title: Text(_selectedVideo == null ? 'Select Video' : 'Video Selected'),
        subtitle: Text(_selectedVideo?.path ?? 'No video selected'),
        leading: Icon(Icons.video_library),
        onTap: _selectVideo,
      ),
    );
  }
  
  Widget _buildTranscriptInput() {
    return TextField(
      decoration: InputDecoration(
        labelText: 'Transcript',
        hintText: 'Enter the text for voiceover...',
        border: OutlineInputBorder(),
      ),
      maxLines: 4,
      onChanged: (value) => _transcript = value,
    );
  }
  
  Widget _buildCreateButton() {
    return ElevatedButton(
      onPressed: (_selectedVideo != null && _transcript.isNotEmpty && _title.isNotEmpty) 
          ? _createVideo : null,
      child: Text('Create YouTube Short'),
    );
  }
  
  Future<void> _createVideo() async {
    setState(() => _isUploading = true);
    
    try {
      // 1. Upload video
      final videoUpload = await UploadService.uploadVideo(_selectedVideo!);
      
      // 2. Upload transcript
      final transcriptUpload = await UploadService.uploadTranscript(_transcript);
      
      setState(() {
        _isUploading = false;
        _isProcessing = true;
      });
      
      // 3. Create job
      final jobRequest = JobCreateRequest(
        title: _title,
        description: _description,
        voice: _selectedVoice,
        tags: _tags,
        videoUploadId: videoUpload.id,
        transcriptUploadId: transcriptUpload.id,
      );
      
      final job = await JobService.createJob(jobRequest);
      _currentJobId = job.id;
      
      // 4. Poll job status
      JobService.pollJobStatus(job.id).listen((status) {
        setState(() => _jobStatus = status);
        
        if (status.status == 'completed') {
          setState(() => _isProcessing = false);
          _showCompletionDialog();
        } else if (status.status == 'failed') {
          setState(() => _isProcessing = false);
          _showErrorDialog(status.errorMessage ?? 'Processing failed');
        }
      });
      
    } catch (e) {
      setState(() {
        _isUploading = false;
        _isProcessing = false;
      });
      _showErrorDialog(e.toString());
    }
  }
  
  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Video Ready!'),
        content: Text('Your YouTube Short has been processed successfully.'),
        actions: [
          TextButton(
            onPressed: () => _uploadToYouTube(),
            child: Text('Upload to YouTube'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _uploadToYouTube() async {
    try {
      final result = await YouTubeService.uploadProcessedVideoToYouTube(
        _currentJobId!,
        _title,
        _description,
        tags: _tags,
      );
      
      // Show success with YouTube URL
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Uploaded to YouTube!'),
          content: Text('Video URL: ${result['video_url']}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorDialog('YouTube upload failed: $e');
    }
  }
}
```

## 6. Error Handling Strategy

```dart
// lib/utils/error_handler.dart
class ErrorHandler {
  static void handleApiError(BuildContext context, dynamic error) {
    String message = 'An unexpected error occurred';
    
    if (error is ApiException) {
      switch (error.statusCode) {
        case 401:
          message = 'Please log in again';
          _redirectToLogin(context);
          break;
        case 403:
          message = 'You don\'t have permission for this action';
          break;
        case 413:
          message = 'File too large. Maximum size is 100MB';
          break;
        case 422:
          message = 'Invalid input data';
          break;
        case 500:
          message = 'Server error. Please try again later';
          break;
        default:
          message = error.message;
      }
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  
  static void _redirectToLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }
}
```

## 7. Build Commands

After implementing the models, run these commands to generate the JSON serialization code:

```bash
# Generate JSON serialization code
flutter packages pub run build_runner build

# Or watch for changes
flutter packages pub run build_runner watch
```

This comprehensive workflow guide provides everything your Flutter team needs to successfully integrate with your YouTube Shorts Creator API. The examples show real-world implementation patterns and handle all the edge cases they'll encounter during development. 
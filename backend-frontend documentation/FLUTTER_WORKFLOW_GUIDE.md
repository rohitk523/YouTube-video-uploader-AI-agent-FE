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
  
  // Upload transcript file
  static Future<UploadResponse> uploadTranscriptFile(File transcriptFile) async {
    final token = await AuthService.getStoredToken();
    if (token == null) throw Exception('Not authenticated');
    
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiService.apiBaseUrl}/upload/transcript-file'),
    );
    
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', transcriptFile.path));
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
  
  // Get upload details
  static Future<UploadResponse> getUpload(String uploadId) async {
    final token = await AuthService.getStoredToken();
    if (token == null) throw Exception('Not authenticated');
    
    final response = await ApiService.makeRequest(
      'GET',
      '/upload/$uploadId',
      token: token,
    );
    
    return UploadResponse.fromJson(json.decode(response.body));
  }
  
  // Delete upload
  static Future<void> deleteUpload(String uploadId) async {
    final token = await AuthService.getStoredToken();
    if (token == null) throw Exception('Not authenticated');
    
    await ApiService.makeRequest(
      'DELETE',
      '/upload/$uploadId',
      token: token,
    );
  }
}
```

### Job Management Service

```dart
// lib/services/job_service.dart
class JobService {
  // Create processing job
  static Future<JobResponse> createJob(JobCreateRequest request) async {
    final token = await AuthService.getStoredToken();
    if (token == null) throw Exception('Not authenticated');
    
    final response = await ApiService.makeRequest(
      'POST',
      '/jobs/create',
      token: token,
      body: json.encode(request.toJson()),
    );
    
    return JobResponse.fromJson(json.decode(response.body));
  }
  
  // Get job details
  static Future<JobResponse> getJob(String jobId) async {
    final token = await AuthService.getStoredToken();
    if (token == null) throw Exception('Not authenticated');
    
    final response = await ApiService.makeRequest(
      'GET',
      '/jobs/$jobId',
      token: token,
    );
    
    return JobResponse.fromJson(json.decode(response.body));
  }
  
  // Get job status with progress
  static Future<JobStatus> getJobStatus(String jobId) async {
    final token = await AuthService.getStoredToken();
    if (token == null) throw Exception('Not authenticated');
    
    final response = await ApiService.makeRequest(
      'GET',
      '/jobs/$jobId/status',
      token: token,
    );
    
    return JobStatus.fromJson(json.decode(response.body));
  }
  
  // List jobs with pagination
  static Future<JobList> listJobs({
    int page = 1,
    int perPage = 20,
    String? statusFilter,
  }) async {
    final token = await AuthService.getStoredToken();
    if (token == null) throw Exception('Not authenticated');
    
    var queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    
    if (statusFilter != null) {
      queryParams['status_filter'] = statusFilter;
    }
    
    final queryString = Uri(queryParameters: queryParams).query;
    final endpoint = '/jobs?$queryString';
    
    final response = await ApiService.makeRequest(
      'GET',
      endpoint,
      token: token,
    );
    
    return JobList.fromJson(json.decode(response.body));
  }
  
  // Delete job
  static Future<void> deleteJob(String jobId) async {
    final token = await AuthService.getStoredToken();
    if (token == null) throw Exception('Not authenticated');
    
    await ApiService.makeRequest(
      'DELETE',
      '/jobs/$jobId',
      token: token,
    );
  }
  
  // Poll job status until completion
  static Stream<JobStatus> pollJobStatus(String jobId) async* {
    while (true) {
      try {
        final status = await getJobStatus(jobId);
        yield status;
        
        if (status.status == 'completed' || status.status == 'failed') {
          break;
        }
        
        await Future.delayed(const Duration(seconds: 5));
      } catch (e) {
        yield JobStatus(
          id: jobId,
          status: 'error',
          progress: 0,
          currentStep: 'error',
          errorMessage: e.toString(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          tempFilesCleaned: false,
          permanentStorage: false,
        );
        break;
      }
    }
  }
}
```

### YouTube Service

```dart
// lib/services/youtube_service.dart
class YouTubeService {
  // Get supported voices
  static Future<SupportedVoices> getSupportedVoices() async {
    final response = await ApiService.makeRequest('GET', '/youtube/voices');
    return SupportedVoices.fromJson(json.decode(response.body));
  }
  
  // Get YouTube service info
  static Future<Map<String, dynamic>> getServiceInfo() async {
    final response = await ApiService.makeRequest('GET', '/youtube/info');
    return json.decode(response.body);
  }
  
  // Download processed video
  static Future<void> downloadProcessedVideo(String jobId, String savePath) async {
    final token = await AuthService.getStoredToken();
    if (token == null) throw Exception('Not authenticated');
    
    final response = await http.get(
      Uri.parse('${ApiService.apiBaseUrl}/youtube/download/$jobId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (response.statusCode == 200) {
      final file = File(savePath);
      await file.writeAsBytes(response.bodyBytes);
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Download failed: ${response.body}',
      );
    }
  }
  
  // Upload processed video to YouTube
  static Future<Map<String, dynamic>> uploadProcessedVideoToYouTube(
    String jobId,
    String title,
    String description, {
    List<String>? tags,
    String category = 'entertainment',
    String privacy = 'public',
  }) async {
    final token = await AuthService.getStoredToken();
    if (token == null) throw Exception('Not authenticated');
    
    final response = await http.post(
      Uri.parse('${ApiService.apiBaseUrl}/youtube/upload-from-job'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Bearer $token',
      },
      body: {
        'job_id': jobId,
        'title': title,
        'description': description,
        'tags': tags?.join(',') ?? '',
        'category': category,
        'privacy': privacy,
      },
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'YouTube upload failed: ${response.body}',
      );
    }
  }
}
```

## 4. Data Models

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
  
  @JsonKey(name: 'profile_picture_url')
  final String? profilePictureUrl;
  
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
    this.profilePictureUrl,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
  
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);
}

@JsonSerializable()
class UserRegisterRequest {
  final String email;
  final String password;
  final String? username;
  
  @JsonKey(name: 'first_name')
  final String? firstName;
  
  @JsonKey(name: 'last_name')
  final String? lastName;
  
  UserRegisterRequest({
    required this.email,
    required this.password,
    this.username,
    this.firstName,
    this.lastName,
  });
  
  factory UserRegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$UserRegisterRequestFromJson(json);
  
  Map<String, dynamic> toJson() => _$UserRegisterRequestToJson(this);
}
```

```dart
// lib/models/upload_models.dart
import 'package:json_annotation/json_annotation.dart';

part 'upload_models.g.dart';

@JsonSerializable()
class UploadResponse {
  final String id;
  final String filename;
  
  @JsonKey(name: 'original_filename')
  final String originalFilename;
  
  @JsonKey(name: 'file_type')
  final String fileType;
  
  @JsonKey(name: 'file_size_mb')
  final double fileSizeMb;
  
  @JsonKey(name: 'upload_time')
  final DateTime uploadTime;
  
  UploadResponse({
    required this.id,
    required this.filename,
    required this.originalFilename,
    required this.fileType,
    required this.fileSizeMb,
    required this.uploadTime,
  });
  
  factory UploadResponse.fromJson(Map<String, dynamic> json) =>
      _$UploadResponseFromJson(json);
  
  Map<String, dynamic> toJson() => _$UploadResponseToJson(this);
}

@JsonSerializable()
class SupportedVoices {
  final List<String> voices;
  
  @JsonKey(name: 'default_voice')
  final String defaultVoice;
  
  SupportedVoices({
    required this.voices,
    required this.defaultVoice,
  });
  
  factory SupportedVoices.fromJson(Map<String, dynamic> json) =>
      _$SupportedVoicesFromJson(json);
  
  Map<String, dynamic> toJson() => _$SupportedVoicesToJson(this);
}
```

```dart
// lib/models/job_models.dart
import 'package:json_annotation/json_annotation.dart';

part 'job_models.g.dart';

@JsonSerializable()
class JobCreateRequest {
  final String title;
  final String description;
  final String voice;
  final List<String> tags;
  
  @JsonKey(name: 'video_upload_id')
  final String videoUploadId;
  
  @JsonKey(name: 'transcript_upload_id')
  final String? transcriptUploadId;
  
  @JsonKey(name: 'transcript_content')
  final String? transcriptContent;
  
  JobCreateRequest({
    required this.title,
    required this.description,
    required this.voice,
    required this.tags,
    required this.videoUploadId,
    this.transcriptUploadId,
    this.transcriptContent,
  });
  
  factory JobCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$JobCreateRequestFromJson(json);
  
  Map<String, dynamic> toJson() => _$JobCreateRequestToJson(this);
}

@JsonSerializable()
class JobResponse {
  final String id;
  final String status;
  final int progress;
  
  @JsonKey(name: 'progress_message')
  final String? progressMessage;
  
  final String title;
  final String description;
  final String voice;
  final List<String> tags;
  
  @JsonKey(name: 'video_upload_id')
  final String? videoUploadId;
  
  @JsonKey(name: 'transcript_upload_id')
  final String? transcriptUploadId;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;
  
  @JsonKey(name: 'error_message')
  final String? errorMessage;
  
  @JsonKey(name: 'youtube_url')
  final String? youtubeUrl;
  
  @JsonKey(name: 'youtube_video_id')
  final String? youtubeVideoId;
  
  JobResponse({
    required this.id,
    required this.status,
    required this.progress,
    this.progressMessage,
    required this.title,
    required this.description,
    required this.voice,
    required this.tags,
    this.videoUploadId,
    this.transcriptUploadId,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.errorMessage,
    this.youtubeUrl,
    this.youtubeVideoId,
  });
  
  factory JobResponse.fromJson(Map<String, dynamic> json) =>
      _$JobResponseFromJson(json);
  
  Map<String, dynamic> toJson() => _$JobResponseToJson(this);
}

@JsonSerializable()
class JobStatus {
  final String id;
  final String status;
  final int progress;
  
  @JsonKey(name: 'progress_message')
  final String? progressMessage;
  
  @JsonKey(name: 'current_step')
  final String currentStep;
  
  @JsonKey(name: 'error_message')
  final String? errorMessage;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;
  
  @JsonKey(name: 'temp_files_cleaned')
  final bool tempFilesCleaned;
  
  @JsonKey(name: 'permanent_storage')
  final bool permanentStorage;
  
  JobStatus({
    required this.id,
    required this.status,
    required this.progress,
    this.progressMessage,
    required this.currentStep,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    required this.tempFilesCleaned,
    required this.permanentStorage,
  });
  
  factory JobStatus.fromJson(Map<String, dynamic> json) =>
      _$JobStatusFromJson(json);
  
  Map<String, dynamic> toJson() => _$JobStatusToJson(this);
}

@JsonSerializable()
class JobList {
  final List<JobResponse> jobs;
  final int total;
  final int page;
  
  @JsonKey(name: 'page_size')
  final int pageSize;
  
  @JsonKey(name: 'total_pages')
  final int totalPages;
  
  JobList({
    required this.jobs,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });
  
  factory JobList.fromJson(Map<String, dynamic> json) =>
      _$JobListFromJson(json);
  
  Map<String, dynamic> toJson() => _$JobListToJson(this);
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
  double _uploadProgress = 0.0;
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
  
  Widget _buildVideoDetails() {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _title = value,
        ),
        SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          onChanged: (value) => _description = value,
        ),
      ],
    );
  }
  
  Widget _buildVoiceSelector() {
    return FutureBuilder<SupportedVoices>(
      future: YouTubeService.getSupportedVoices(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        
        return DropdownButtonFormField<String>(
          value: _selectedVoice,
          decoration: InputDecoration(
            labelText: 'Voice',
            border: OutlineInputBorder(),
          ),
          items: snapshot.data!.voices.map((voice) {
            return DropdownMenuItem(value: voice, child: Text(voice));
          }).toList(),
          onChanged: (value) => setState(() => _selectedVoice = value!),
        );
      },
    );
  }
  
  Widget _buildCreateButton() {
    return ElevatedButton(
      onPressed: (_selectedVideo != null && _transcript.isNotEmpty && _title.isNotEmpty) 
          ? _createVideo : null,
      child: Text('Create YouTube Short'),
    );
  }
  
  Widget _buildProgressIndicator() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            if (_isUploading) ...[
              Text('Uploading files...'),
              LinearProgressIndicator(value: _uploadProgress),
            ],
            if (_isProcessing && _jobStatus != null) ...[
              Text('Processing video...'),
              LinearProgressIndicator(value: _jobStatus!.progress / 100),
              Text(_jobStatus!.progressMessage ?? ''),
            ],
          ],
        ),
      ),
    );
  }
  
  Future<void> _selectVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowedExtensions: ['mp4', 'mov', 'avi', 'mkv'],
    );
    
    if (result != null) {
      setState(() {
        _selectedVideo = File(result.files.single.path!);
      });
    }
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
            onPressed: () => Navigator.pop(context),
            child: Text('Download'),
          ),
          TextButton(
            onPressed: () => _uploadToYouTube(),
            child: Text('Upload to YouTube'),
          ),
        ],
      ),
    );
  }
  
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
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

## 7. Testing Strategy

### Unit Tests
```dart
// test/services/auth_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('AuthService', () {
    test('login returns AuthResponse on success', () async {
      // Mock HTTP response and test login flow
    });
    
    test('login throws ApiException on failure', () async {
      // Test error handling
    });
    
    test('refreshToken updates stored tokens', () async {
      // Test token refresh
    });
  });
}
```

### Integration Tests
```dart
// integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('End-to-End Tests', () {
    testWidgets('Complete video creation flow', (tester) async {
      // Test the entire workflow from login to video creation
    });
  });
}
```

## 8. Build Commands

After implementing the models, run these commands to generate the JSON serialization code:

```bash
# Generate JSON serialization code
flutter packages pub run build_runner build

# Or watch for changes
flutter packages pub run build_runner watch
```

This comprehensive workflow guide provides everything your Flutter team needs to successfully integrate with your YouTube Shorts Creator API. The examples show real-world implementation patterns and handle all the edge cases they'll encounter during development. 
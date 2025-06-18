# YouTube Shorts Creator API - Flutter Integration Guide

## Overview

This document provides comprehensive API documentation for integrating the Flutter frontend with the YouTube Shorts Creator Backend API. The API uses FastAPI with OAuth 2.0 authentication and supports video upload, processing, and YouTube automation.

## Base URL

- **Development**: `http://localhost:8000`
- **Production**: `https://your-production-domain.com`

## Authentication

### OAuth 2.0 Implementation

The API uses OAuth 2.0 with Bearer tokens. All authenticated endpoints require an `Authorization` header:

```
Authorization: Bearer <access_token>
```

### Supported Grant Types

1. **Password Grant** (for user login)
2. **Refresh Token Grant** (for token renewal)
3. **Authorization Code Flow** (for advanced integrations)

### Scopes

- `read`: Read access to user data
- `write`: Write access to user data
- `upload`: Upload files and create content
- `youtube`: Access to YouTube operations
- `admin`: Administrative access

---

## Authentication Endpoints

### 1. User Registration

**POST** `/api/v1/oauth/register`

Register a new user account.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "username": "johndoe",
  "first_name": "John",
  "last_name": "Doe"
}
```

**Response (201 Created):**
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "token_type": "bearer",
  "expires_in": 1800,
  "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "username": "johndoe",
    "first_name": "John",
    "last_name": "Doe",
    "is_active": true,
    "is_verified": false,
    "profile_picture_url": null,
    "provider": null,
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:30:00Z",
    "last_login_at": null
  }
}
```

### 2. User Login (Token Generation)

**POST** `/api/v1/oauth/token`

**Content-Type:** `application/x-www-form-urlencoded`

**Request Body:**
```
grant_type=password
username=user@example.com
password=password123
scope=read write upload youtube
```

**Response (200 OK):**
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "token_type": "bearer",
  "expires_in": 1800,
  "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "scope": "read write upload youtube"
}
```

### 3. Refresh Token

**POST** `/api/v1/oauth/token/refresh`

**Request Body:**
```json
{
  "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
}
```

**Response (200 OK):**
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "token_type": "bearer",
  "expires_in": 1800,
  "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "scope": "read write upload youtube"
}
```

### 4. Get User Profile

**GET** `/api/v1/oauth/userinfo`

**Headers:** `Authorization: Bearer <access_token>`

**Response (200 OK):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "username": "johndoe",
  "first_name": "John",
  "last_name": "Doe",
  "is_active": true,
  "is_verified": true,
  "profile_picture_url": "https://example.com/avatar.jpg",
  "provider": null,
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-15T10:30:00Z",
  "last_login_at": "2024-01-15T14:20:00Z"
}
```

### 5. Update User Profile

**PUT** `/api/v1/oauth/profile`

**Headers:** `Authorization: Bearer <access_token>`

**Request Body:**
```json
{
  "username": "newusername",
  "first_name": "Jane",
  "last_name": "Smith",
  "profile_picture_url": "https://example.com/new-avatar.jpg"
}
```

**Response (200 OK):** Same as Get User Profile

### 6. Change Password

**POST** `/api/v1/oauth/change-password`

**Headers:** `Authorization: Bearer <access_token>`

**Request Body:**
```json
{
  "current_password": "oldpassword123",
  "new_password": "newpassword456"
}
```

**Response (200 OK):**
```json
{
  "message": "Password changed successfully"
}
```

### 7. Logout

**POST** `/api/v1/oauth/logout`

**Headers:** `Authorization: Bearer <access_token>`

**Response (200 OK):**
```json
{
  "message": "Successfully logged out"
}
```

---

## File Upload Endpoints

### 1. Check S3 Configuration

**GET** `/api/v1/upload/config/check`

**Headers:** `Authorization: Bearer <access_token>`

**Response (200 OK):**
```json
{
  "status": "success",
  "s3_configuration": {
    "aws_access_key_id_configured": true,
    "aws_secret_access_key_configured": true,
    "s3_bucket_name_configured": true,
    "aws_region": "us-east-1",
    "s3_bucket_name": "my-youtube-bucket",
    "all_configured": true,
    "s3_connection_status": "Success",
    "s3_service_available": true
  },
  "recommendations": ["S3 is properly configured!"]
}
```

### 2. Upload Video File

**POST** `/api/v1/upload/video`

**Headers:** 
- `Authorization: Bearer <access_token>`
- `Content-Type: multipart/form-data`

**Request Body:**
```
file: <video_file>
is_temp: true
```

**Response (200 OK):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "filename": "video_abc123.mp4",
  "original_filename": "my_video.mp4",
  "file_type": "video",
  "file_size_mb": 25.5,
  "upload_time": "2024-01-15T10:30:00Z"
}
```

### 3. Upload Transcript Text

**POST** `/api/v1/upload/transcript-text`

**Headers:** `Authorization: Bearer <access_token>`

**Request Body:**
```json
{
  "content": "This is the transcript content for text-to-speech generation..."
}
```

**Query Parameters:**
- `is_temp` (boolean, default: true): Whether this is a temporary upload

**Response (200 OK):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440001",
  "filename": "transcript_xyz789.txt",
  "original_filename": "transcript.txt",
  "file_type": "transcript",
  "file_size_mb": 0.001,
  "upload_time": "2024-01-15T10:35:00Z"
}
```

### 4. Upload Transcript File

**POST** `/api/v1/upload/transcript-file`

**Headers:** 
- `Authorization: Bearer <access_token>`
- `Content-Type: multipart/form-data`

**Request Body:**
```
file: <transcript_file>
is_temp: true
```

**Response (200 OK):** Same as Upload Transcript Text

### 5. Get Upload Details

**GET** `/api/v1/upload/{upload_id}`

**Headers:** `Authorization: Bearer <access_token>`

**Response (200 OK):** Same as upload response format

### 6. Download Upload

**GET** `/api/v1/upload/{upload_id}/download`

**Headers:** `Authorization: Bearer <access_token>`

**Query Parameters:**
- `use_presigned` (boolean, default: true): Use presigned URL for download

**Response (302 Redirect):** Redirects to download URL

### 7. Delete Upload

**DELETE** `/api/v1/upload/{upload_id}`

**Headers:** `Authorization: Bearer <access_token>`

**Response (200 OK):**
```json
{
  "status": "success",
  "message": "Upload deleted successfully"
}
```

---

## Job Management Endpoints

### 1. Create Processing Job

**POST** `/api/v1/jobs/create`

**Headers:** `Authorization: Bearer <access_token>`

**Request Body:**
```json
{
  "title": "My YouTube Short",
  "description": "A great short video about technology",
  "voice": "alloy",
  "tags": ["tech", "shorts", "ai"],
  "video_upload_id": "550e8400-e29b-41d4-a716-446655440000",
  "transcript_upload_id": "550e8400-e29b-41d4-a716-446655440001"
}
```

**Alternative with direct transcript:**
```json
{
  "title": "My YouTube Short",
  "description": "A great short video about technology",
  "voice": "nova",
  "tags": ["tech", "shorts", "ai"],
  "video_upload_id": "550e8400-e29b-41d4-a716-446655440000",
  "transcript_content": "This is the transcript content..."
}
```

**Response (200 OK):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440002",
  "status": "processing",
  "progress": 0,
  "progress_message": "Job created successfully",
  "title": "My YouTube Short",
  "description": "A great short video about technology",
  "voice": "alloy",
  "tags": ["tech", "shorts", "ai"],
  "video_upload_id": "550e8400-e29b-41d4-a716-446655440000",
  "transcript_upload_id": "550e8400-e29b-41d4-a716-446655440001",
  "created_at": "2024-01-15T10:40:00Z",
  "updated_at": "2024-01-15T10:40:00Z",
  "completed_at": null,
  "error_message": null,
  "processed_video_s3_key": null,
  "audio_s3_key": null,
  "final_video_s3_key": null,
  "youtube_url": null,
  "youtube_video_id": null,
  "temp_files_cleaned": false,
  "permanent_storage": false,
  "video_duration": null,
  "processing_time_seconds": null,
  "file_size_mb": null
}
```

### 2. Get Job Details

**GET** `/api/v1/jobs/{job_id}`

**Headers:** `Authorization: Bearer <access_token>`

**Response (200 OK):** Same as Create Job response

### 3. Get Job Status

**GET** `/api/v1/jobs/{job_id}/status`

**Headers:** `Authorization: Bearer <access_token>`

**Response (200 OK):**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440002",
  "status": "processing",
  "progress": 45,
  "progress_message": "Generating audio from transcript...",
  "current_step": "audio_generation",
  "error_message": null,
  "created_at": "2024-01-15T10:40:00Z",
  "updated_at": "2024-01-15T10:42:30Z",
  "completed_at": null,
  "temp_files_cleaned": false,
  "permanent_storage": false
}
```

### 4. List Jobs

**GET** `/api/v1/jobs`

**Headers:** `Authorization: Bearer <access_token>`

**Query Parameters:**
- `page` (integer, default: 1): Page number
- `per_page` (integer, default: 20, max: 100): Items per page
- `status_filter` (string, optional): Filter by status

**Response (200 OK):**
```json
{
  "jobs": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440002",
      "status": "completed",
      "progress": 100,
      "title": "My YouTube Short",
      "created_at": "2024-01-15T10:40:00Z"
    }
  ],
  "total": 25,
  "page": 1,
  "page_size": 20,
  "total_pages": 2
}
```

### 5. Delete Job

**DELETE** `/api/v1/jobs/{job_id}`

**Headers:** `Authorization: Bearer <access_token>`

**Response (200 OK):**
```json
{
  "status": "success",
  "message": "Job deleted successfully"
}
```

---

## YouTube Endpoints

### 1. Get Supported Voices

**GET** `/api/v1/youtube/voices`

**Response (200 OK):**
```json
{
  "voices": ["alloy", "echo", "fable", "onyx", "nova", "shimmer"],
  "default_voice": "alloy"
}
```

### 2. Get YouTube Service Info

**GET** `/api/v1/youtube/info`

**Response (200 OK):**
```json
{
  "service": "YouTube Shorts Creator",
  "capabilities": {
    "video_processing": true,
    "tts_generation": true,
    "youtube_upload": true,
    "supported_formats": ["mp4", "mov", "avi", "mkv"],
    "max_duration": 60,
    "output_format": "mp4",
    "output_resolution": "1080x1920"
  },
  "supported_voices": ["alloy", "echo", "fable", "onyx", "nova", "shimmer"],
  "processing_steps": [
    "Video processing and formatting",
    "Text-to-speech audio generation",
    "Audio and video combination",
    "YouTube upload and publishing"
  ],
  "estimated_processing_time": "2-5 minutes per video"
}
```

### 3. Download Processed Video

**GET** `/api/v1/youtube/download/{job_id}`

**Headers:** `Authorization: Bearer <access_token>`

**Response (200 OK):** File download response

### 4. Upload Video to YouTube Directly

**POST** `/api/v1/youtube/upload-direct`

**Headers:** 
- `Authorization: Bearer <access_token>`
- `Content-Type: multipart/form-data`

**Request Body:**
```
file: <video_file>
title: "My YouTube Short"
description: "Video description"
tags: "tag1,tag2,tag3"
category: "entertainment"
privacy: "public"
```

**Response (200 OK):**
```json
{
  "success": true,
  "video_id": "dQw4w9WgXcQ",
  "video_url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
  "message": "Video uploaded successfully to YouTube"
}
```

### 5. Upload Processed Video to YouTube

**POST** `/api/v1/youtube/upload-from-job`

**Headers:** `Authorization: Bearer <access_token>`

**Request Body:**
```
job_id: "550e8400-e29b-41d4-a716-446655440002"
title: "My Processed YouTube Short"
description: "Processed video description"
tags: "processed,ai,shorts"
category: "entertainment"
privacy: "public"
```

**Response (200 OK):** Same as Upload Direct

---

## System Endpoints

### 1. Health Check

**GET** `/api/v1/health`

**Response (200 OK):**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00Z",
  "version": "1.0.0",
  "database_connected": true,
  "upload_directory_accessible": true
}
```

### 2. API Information

**GET** `/api/v1/info`

**Response (200 OK):**
```json
{
  "name": "YouTube Shorts Creator API",
  "version": "1.0.0",
  "description": "Create YouTube Shorts with AI voiceover using Google ADK"
}
```

### 3. Root Endpoint

**GET** `/`

**Response (200 OK):**
```json
{
  "message": "Welcome to YouTube Shorts Creator API",
  "version": "1.0.0",
  "docs": "/docs",
  "status": "operational"
}
```

---

## Error Handling

### Standard Error Response

All errors follow this format:

```json
{
  "detail": "Error message description"
}
```

### HTTP Status Codes

- `200`: Success
- `201`: Created (for registration)
- `400`: Bad Request (validation errors)
- `401`: Unauthorized (authentication required)
- `403`: Forbidden (insufficient permissions)
- `404`: Not Found
- `413`: Payload Too Large (file size exceeded)
- `422`: Unprocessable Entity (validation errors)
- `500`: Internal Server Error

### Common Error Examples

**401 Unauthorized:**
```json
{
  "detail": "Could not validate credentials"
}
```

**400 Bad Request:**
```json
{
  "detail": "File too large. Maximum size: 100MB"
}
```

**422 Validation Error:**
```json
{
  "detail": [
    {
      "loc": ["body", "email"],
      "msg": "field required",
      "type": "value_error.missing"
    }
  ]
}
```

---

## Flutter Integration Examples

### 1. Authentication Service

```dart
class AuthService {
  static const String baseUrl = 'http://localhost:8000';
  
  static Future<AuthResponse> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/oauth/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'password',
        'username': email,
        'password': password,
        'scope': 'read write upload youtube',
      },
    );
    
    if (response.statusCode == 200) {
      return AuthResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }
  
  static Future<AuthResponse> refreshToken(String refreshToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/oauth/token/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'refresh_token': refreshToken}),
    );
    
    if (response.statusCode == 200) {
      return AuthResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Token refresh failed');
    }
  }
}
```

### 2. File Upload Service

```dart
class UploadService {
  static const String baseUrl = 'http://localhost:8000';
  
  static Future<UploadResponse> uploadVideo(File videoFile, String token) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/v1/upload/video'),
    );
    
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', videoFile.path));
    request.fields['is_temp'] = 'true';
    
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      return UploadResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Upload failed: ${response.body}');
    }
  }
  
  static Future<UploadResponse> uploadTranscript(String content, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/upload/transcript-text'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'content': content}),
    );
    
    if (response.statusCode == 200) {
      return UploadResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Transcript upload failed: ${response.body}');
    }
  }
}
```

### 3. Job Management Service

```dart
class JobService {
  static const String baseUrl = 'http://localhost:8000';
  
  static Future<JobResponse> createJob(JobCreateRequest request, String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/jobs/create'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(request.toJson()),
    );
    
    if (response.statusCode == 200) {
      return JobResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Job creation failed: ${response.body}');
    }
  }
  
  static Future<JobStatus> getJobStatus(String jobId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/jobs/$jobId/status'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (response.statusCode == 200) {
      return JobStatus.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to get job status: ${response.body}');
    }
  }
}
```

### 4. Data Models

```dart
class AuthResponse {
  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final String? refreshToken;
  final UserProfile? user;
  
  AuthResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    this.refreshToken,
    this.user,
  });
  
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'],
      tokenType: json['token_type'],
      expiresIn: json['expires_in'],
      refreshToken: json['refresh_token'],
      user: json['user'] != null ? UserProfile.fromJson(json['user']) : null,
    );
  }
}

class UploadResponse {
  final String id;
  final String filename;
  final String originalFilename;
  final String fileType;
  final double fileSizeMb;
  final DateTime uploadTime;
  
  UploadResponse({
    required this.id,
    required this.filename,
    required this.originalFilename,
    required this.fileType,
    required this.fileSizeMb,
    required this.uploadTime,
  });
  
  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(
      id: json['id'],
      filename: json['filename'],
      originalFilename: json['original_filename'],
      fileType: json['file_type'],
      fileSizeMb: json['file_size_mb'].toDouble(),
      uploadTime: DateTime.parse(json['upload_time']),
    );
  }
}

class JobCreateRequest {
  final String title;
  final String description;
  final String voice;
  final List<String> tags;
  final String videoUploadId;
  final String? transcriptUploadId;
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
  
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'voice': voice,
      'tags': tags,
      'video_upload_id': videoUploadId,
      if (transcriptUploadId != null) 'transcript_upload_id': transcriptUploadId,
      if (transcriptContent != null) 'transcript_content': transcriptContent,
    };
  }
}
```

---

## Configuration Requirements

### Environment Variables

Ensure these environment variables are set for the backend:

```env
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/youtube_shorts

# AWS S3
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key
S3_BUCKET_NAME=your-youtube-bucket
AWS_REGION=us-east-1

# OpenAI
OPENAI_API_KEY=your_openai_api_key

# YouTube
YOUTUBE_CLIENT_ID=your_youtube_client_id
YOUTUBE_CLIENT_SECRET=your_youtube_client_secret

# Security
SECRET_KEY=your-secure-secret-key

# CORS
CORS_ORIGINS_STR=http://localhost:3000,https://your-flutter-app.com
```

### File Upload Limits

- **Maximum file size**: 100MB (configurable)
- **Supported video formats**: mp4, mov, avi, mkv
- **Supported transcript formats**: txt, md

### Rate Limits

- Authentication endpoints: Standard rate limiting
- File upload endpoints: Large file handling with progress tracking
- Job processing: Background task processing with status updates

---

## WebSocket Support (Future Enhancement)

For real-time job progress updates, consider implementing WebSocket connections:

```dart
// Example WebSocket implementation for job progress
class JobProgressWebSocket {
  late WebSocketChannel channel;
  
  void connectToJobProgress(String jobId, String token) {
    channel = WebSocketChannel.connect(
      Uri.parse('ws://localhost:8000/ws/jobs/$jobId/progress?token=$token'),
    );
    
    channel.stream.listen((data) {
      final progress = json.decode(data);
      // Update UI with progress
    });
  }
}
```

---

## Testing Endpoints

Use these endpoints for testing integration:

1. **Health Check**: Start with `/api/v1/health` to verify connectivity
2. **Authentication**: Test login flow with `/api/v1/oauth/token`
3. **File Upload**: Test with small files first at `/api/v1/upload/video`
4. **Job Creation**: Create a simple job with transcript text
5. **Job Status**: Poll job status during processing

---

## Support and Documentation

- **API Documentation**: Available at `/docs` (Swagger UI)
- **Alternative Documentation**: Available at `/redoc` (ReDoc)
- **OpenAPI Schema**: Available at `/openapi.json`

This documentation provides everything your Flutter team needs to integrate with the YouTube Shorts Creator API. The examples show typical usage patterns and all request/response formats are documented with real-world examples. 
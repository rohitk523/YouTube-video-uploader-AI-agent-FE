import 'package:equatable/equatable.dart';

// Job status enum
enum JobStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled;

  static JobStatus fromString(String status) {
    return JobStatus.values.firstWhere(
      (e) => e.name == status.toLowerCase(),
      orElse: () => JobStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case JobStatus.pending:
        return 'Pending';
      case JobStatus.processing:
        return 'Processing';
      case JobStatus.completed:
        return 'Completed';
      case JobStatus.failed:
        return 'Failed';
      case JobStatus.cancelled:
        return 'Cancelled';
    }
  }
}

// Create job request model
class CreateJobRequest extends Equatable {
  final String videoUploadId;
  final String transcriptUploadId;
  final String title;
  final String description;
  final String voice;
  final List<String> tags;
  final bool mockMode;

  const CreateJobRequest({
    required this.videoUploadId,
    required this.transcriptUploadId,
    required this.title,
    required this.description,
    required this.voice,
    required this.tags,
    this.mockMode = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'video_upload_id': videoUploadId,
      'transcript_upload_id': transcriptUploadId,
      'title': title,
      'description': description,
      'voice': voice,
      'tags': tags,
      'mock_mode': mockMode,
    };
  }

  @override
  List<Object?> get props => [
    videoUploadId, transcriptUploadId, title, description, voice, tags, mockMode
  ];
}

// Job model
class Job extends Equatable {
  final String id;
  final JobStatus status;
  final int progress;
  final String progressMessage;
  final String title;
  final String description;
  final String voice;
  final List<String> tags;
  final String videoUploadId;
  final String? transcriptUploadId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final String? processedVideoS3Key;
  final String? audioS3Key;
  final String? finalVideoS3Key;
  final String? youtubeUrl;
  final String? youtubeVideoId;
  final bool tempFilesCleaned;
  final bool permanentStorage;
  final double? videoDuration;
  final int? processingTimeSeconds;
  final double? fileSizeMb;
  final bool mockMode;
  final String? finalVideoPath;

  const Job({
    required this.id,
    required this.status,
    required this.progress,
    required this.progressMessage,
    required this.title,
    required this.description,
    required this.voice,
    required this.tags,
    required this.videoUploadId,
    this.transcriptUploadId,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.errorMessage,
    this.processedVideoS3Key,
    this.audioS3Key,
    this.finalVideoS3Key,
    this.youtubeUrl,
    this.youtubeVideoId,
    required this.tempFilesCleaned,
    required this.permanentStorage,
    this.videoDuration,
    this.processingTimeSeconds,
    this.fileSizeMb,
    this.mockMode = false,
    this.finalVideoPath,
  });

  factory Job.fromJson(Map<String, dynamic> json) => Job(
    id: json['id'] as String,
    status: JobStatus.fromString(json['status'] as String),
    progress: json['progress'] as int,
    progressMessage: json['progress_message'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    voice: json['voice'] as String,
    tags: (json['tags'] as List<dynamic>).cast<String>(),
    videoUploadId: json['video_upload_id'] as String,
    transcriptUploadId: json['transcript_upload_id'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    completedAt: json['completed_at'] != null 
      ? DateTime.parse(json['completed_at'] as String) 
      : null,
    errorMessage: json['error_message'] as String?,
    processedVideoS3Key: json['processed_video_s3_key'] as String?,
    audioS3Key: json['audio_s3_key'] as String?,
    finalVideoS3Key: json['final_video_s3_key'] as String?,
    youtubeUrl: json['youtube_url'] as String?,
    youtubeVideoId: json['youtube_video_id'] as String?,
    tempFilesCleaned: json['temp_files_cleaned'] as bool,
    permanentStorage: json['permanent_storage'] as bool,
    videoDuration: json['video_duration'] != null 
      ? (json['video_duration'] as num).toDouble() 
      : null,
    processingTimeSeconds: json['processing_time_seconds'] as int?,
    fileSizeMb: json['file_size_mb'] != null 
      ? (json['file_size_mb'] as num).toDouble() 
      : null,
    mockMode: json['mock_mode'] as bool? ?? false,
    finalVideoPath: json['final_video_path'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'status': status.name,
    'progress': progress,
    'progress_message': progressMessage,
    'title': title,
    'description': description,
    'voice': voice,
    'tags': tags,
    'video_upload_id': videoUploadId,
    if (transcriptUploadId != null) 'transcript_upload_id': transcriptUploadId,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
    if (errorMessage != null) 'error_message': errorMessage,
    if (processedVideoS3Key != null) 'processed_video_s3_key': processedVideoS3Key,
    if (audioS3Key != null) 'audio_s3_key': audioS3Key,
    if (finalVideoS3Key != null) 'final_video_s3_key': finalVideoS3Key,
    if (youtubeUrl != null) 'youtube_url': youtubeUrl,
    if (youtubeVideoId != null) 'youtube_video_id': youtubeVideoId,
    'temp_files_cleaned': tempFilesCleaned,
    'permanent_storage': permanentStorage,
    if (videoDuration != null) 'video_duration': videoDuration,
    if (processingTimeSeconds != null) 'processing_time_seconds': processingTimeSeconds,
    if (fileSizeMb != null) 'file_size_mb': fileSizeMb,
    'mock_mode': mockMode,
    if (finalVideoPath != null) 'final_video_path': finalVideoPath,
  };

  bool get isCompleted => status == JobStatus.completed;
  bool get isFailed => status == JobStatus.failed;
  bool get isProcessing => status == JobStatus.processing;
  bool get canBeRetried => status == JobStatus.failed || status == JobStatus.cancelled;

  Job copyWith({
    String? id,
    JobStatus? status,
    int? progress,
    String? progressMessage,
    String? title,
    String? description,
    String? voice,
    List<String>? tags,
    String? videoUploadId,
    String? transcriptUploadId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    String? errorMessage,
    String? processedVideoS3Key,
    String? audioS3Key,
    String? finalVideoS3Key,
    String? youtubeUrl,
    String? youtubeVideoId,
    bool? tempFilesCleaned,
    bool? permanentStorage,
    double? videoDuration,
    int? processingTimeSeconds,
    double? fileSizeMb,
    bool? mockMode,
    String? finalVideoPath,
  }) => Job(
    id: id ?? this.id,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    progressMessage: progressMessage ?? this.progressMessage,
    title: title ?? this.title,
    description: description ?? this.description,
    voice: voice ?? this.voice,
    tags: tags ?? this.tags,
    videoUploadId: videoUploadId ?? this.videoUploadId,
    transcriptUploadId: transcriptUploadId ?? this.transcriptUploadId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    completedAt: completedAt ?? this.completedAt,
    errorMessage: errorMessage ?? this.errorMessage,
    processedVideoS3Key: processedVideoS3Key ?? this.processedVideoS3Key,
    audioS3Key: audioS3Key ?? this.audioS3Key,
    finalVideoS3Key: finalVideoS3Key ?? this.finalVideoS3Key,
    youtubeUrl: youtubeUrl ?? this.youtubeUrl,
    youtubeVideoId: youtubeVideoId ?? this.youtubeVideoId,
    tempFilesCleaned: tempFilesCleaned ?? this.tempFilesCleaned,
    permanentStorage: permanentStorage ?? this.permanentStorage,
    videoDuration: videoDuration ?? this.videoDuration,
    processingTimeSeconds: processingTimeSeconds ?? this.processingTimeSeconds,
    fileSizeMb: fileSizeMb ?? this.fileSizeMb,
    mockMode: mockMode ?? this.mockMode,
    finalVideoPath: finalVideoPath ?? this.finalVideoPath,
  );

  @override
  List<Object?> get props => [
    id, status, progress, progressMessage, title, description, voice, tags,
    videoUploadId, transcriptUploadId, createdAt, updatedAt, completedAt,
    errorMessage, processedVideoS3Key, audioS3Key, finalVideoS3Key,
    youtubeUrl, youtubeVideoId, tempFilesCleaned, permanentStorage,
    videoDuration, processingTimeSeconds, fileSizeMb, mockMode, finalVideoPath,
  ];
}

// Job response model (used for API responses)
class JobResponse extends Equatable {
  final String jobId;
  final String videoUploadId;
  final String transcriptUploadId;
  final String outputTitle;
  final String? outputDescription;
  final String? voice;
  final bool autoUpload;
  final String status;
  final double? progressPercentage;
  final String? errorMessage;
  final String? youtubeUrl;
  final String? outputVideoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool mockMode;
  final String? finalVideoPath;

  const JobResponse({
    required this.jobId,
    required this.videoUploadId,
    required this.transcriptUploadId,
    required this.outputTitle,
    this.outputDescription,
    this.voice,
    required this.autoUpload,
    required this.status,
    this.progressPercentage,
    this.errorMessage,
    this.youtubeUrl,
    this.outputVideoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.mockMode = false,
    this.finalVideoPath,
  });

  factory JobResponse.fromJson(Map<String, dynamic> json) => JobResponse(
    jobId: json['id'] as String,
    videoUploadId: json['video_upload_id'] as String,
    transcriptUploadId: json['transcript_upload_id'] as String,
    outputTitle: json['title'] as String,
    outputDescription: json['description'] as String?,
    voice: json['voice'] as String?,
    autoUpload: json['auto_upload'] as bool? ?? false,
    status: json['status'] as String,
    progressPercentage: json['progress'] != null 
      ? (json['progress'] as num).toDouble() 
      : null,
    errorMessage: json['error_message'] as String?,
    youtubeUrl: json['youtube_url'] as String?,
    outputVideoUrl: json['output_video_url'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    mockMode: json['mock_mode'] as bool? ?? false,
    finalVideoPath: json['final_video_path'] as String?,
  );

  @override
  List<Object?> get props => [
    jobId, videoUploadId, transcriptUploadId, outputTitle, outputDescription,
    voice, autoUpload, status, progressPercentage, errorMessage,
    youtubeUrl, outputVideoUrl, createdAt, updatedAt, mockMode, finalVideoPath,
  ];
}

// Job status response model
class JobStatusResponse extends Equatable {
  final String id;
  final String status;
  final double? progressPercentage;
  final String? errorMessage;
  final String? youtubeUrl;
  final String? outputVideoUrl;
  final DateTime? lastUpdated;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final bool tempFilesCleaned;
  final bool permanentStorage;
  final bool mockMode;
  final String? finalVideoPath;

  const JobStatusResponse({
    required this.id,
    required this.status,
    this.progressPercentage,
    this.errorMessage,
    this.youtubeUrl,
    this.outputVideoUrl,
    this.lastUpdated,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    required this.tempFilesCleaned,
    required this.permanentStorage,
    this.mockMode = false,
    this.finalVideoPath,
  });

  factory JobStatusResponse.fromJson(Map<String, dynamic> json) => JobStatusResponse(
    id: json['id'] as String,
    status: json['status'] as String,
    progressPercentage: json['progress_percentage'] != null 
      ? (json['progress_percentage'] as num).toDouble() 
      : null,
    errorMessage: json['error_message'] as String?,
    youtubeUrl: json['youtube_url'] as String?,
    outputVideoUrl: json['output_video_url'] as String?,
    lastUpdated: json['last_updated'] != null 
      ? DateTime.parse(json['last_updated'] as String) 
      : null,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    completedAt: json['completed_at'] != null 
      ? DateTime.parse(json['completed_at'] as String) 
      : null,
    tempFilesCleaned: json['temp_files_cleaned'] as bool,
    permanentStorage: json['permanent_storage'] as bool,
    mockMode: json['mock_mode'] as bool? ?? false,
    finalVideoPath: json['final_video_path'] as String?,
  );

  @override
  List<Object?> get props => [
    id, status, progressPercentage, errorMessage, youtubeUrl, outputVideoUrl,
    lastUpdated, createdAt, updatedAt, completedAt, tempFilesCleaned, permanentStorage,
    mockMode, finalVideoPath,
  ];
}

// Job list item model (simplified for list view)
class JobListItem extends Equatable {
  final String id;
  final JobStatus status;
  final int progress;
  final String title;
  final DateTime createdAt;
  final bool mockMode;
  final String? youtubeUrl;

  const JobListItem({
    required this.id,
    required this.status,
    required this.progress,
    required this.title,
    required this.createdAt,
    this.mockMode = false,
    this.youtubeUrl,
  });

  factory JobListItem.fromJson(Map<String, dynamic> json) => JobListItem(
    id: json['id'] as String,
    status: JobStatus.fromString(json['status'] as String),
    progress: json['progress'] as int,
    title: json['title'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    mockMode: json['mock_mode'] as bool? ?? false,
    youtubeUrl: json['youtube_url'] as String?,
  );

  @override
  List<Object?> get props => [id, status, progress, title, createdAt, mockMode, youtubeUrl];
}

// Job list response model
class JobListResponse extends Equatable {
  final List<JobListItem> jobs;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  const JobListResponse({
    required this.jobs,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory JobListResponse.fromJson(Map<String, dynamic> json) => JobListResponse(
    jobs: (json['jobs'] as List<dynamic>)
        .map((job) => JobListItem.fromJson(job))
        .toList(),
    total: json['total'] as int,
    page: json['page'] as int,
    pageSize: json['page_size'] as int,
    totalPages: json['total_pages'] as int,
  );

  @override
  List<Object> get props => [jobs, total, page, pageSize, totalPages];
}

// YouTube upload request model
class YouTubeUploadRequest extends Equatable {
  final String jobId;

  const YouTubeUploadRequest({required this.jobId});

  Map<String, dynamic> toJson() => {
    'job_id': jobId,
  };

  @override
  List<Object> get props => [jobId];
}

// Voice option model
class VoiceOption extends Equatable {
  final String value;
  final String displayName;

  const VoiceOption({
    required this.value,
    required this.displayName,
  });

  @override
  List<Object> get props => [value, displayName];
}

// Voices response model
class VoicesResponse extends Equatable {
  final List<String> voices;
  final String defaultVoice;

  const VoicesResponse({
    required this.voices,
    required this.defaultVoice,
  });

  factory VoicesResponse.fromJson(Map<String, dynamic> json) => VoicesResponse(
    voices: (json['voices'] as List<dynamic>).cast<String>(),
    defaultVoice: json['default_voice'] as String,
  );

  List<VoiceOption> get voiceOptions => voices.map((voice) => VoiceOption(
    value: voice,
    displayName: voice.substring(0, 1).toUpperCase() + voice.substring(1),
  )).toList();

  @override
  List<Object> get props => [voices, defaultVoice];
} 
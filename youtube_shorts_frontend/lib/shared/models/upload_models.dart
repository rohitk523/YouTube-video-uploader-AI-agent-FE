import 'package:equatable/equatable.dart';

// Upload response model
class UploadResponse extends Equatable {
  final String id;
  final String uploadId;
  final String filename;
  final String originalFilename;
  final String fileType;
  final double fileSizeMb;
  final DateTime uploadTime;

  const UploadResponse({
    required this.id,
    required this.uploadId,
    required this.filename,
    required this.originalFilename,
    required this.fileType,
    required this.fileSizeMb,
    required this.uploadTime,
  });

  factory UploadResponse.fromJson(Map<String, dynamic> json) => UploadResponse(
    id: json['id'] as String,
    uploadId: (json['upload_id'] as String?) ?? (json['id'] as String),
    filename: json['filename'] as String,
    originalFilename: json['original_filename'] as String,
    fileType: json['file_type'] as String,
    fileSizeMb: (json['file_size_mb'] as num).toDouble(),
    uploadTime: DateTime.parse(json['upload_time'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'upload_id': uploadId,
    'filename': filename,
    'original_filename': originalFilename,
    'file_type': fileType,
    'file_size_mb': fileSizeMb,
    'upload_time': uploadTime.toIso8601String(),
  };

  @override
  List<Object> get props => [id, uploadId, filename, originalFilename, fileType, fileSizeMb, uploadTime];
}

// Transcript upload request model
class TranscriptUploadRequest extends Equatable {
  final String content;
  final bool isTemp;

  const TranscriptUploadRequest({
    required this.content,
    this.isTemp = true,
  });

  Map<String, dynamic> toJson() => {
    'content': content,
  };

  @override
  List<Object> get props => [content, isTemp];
}

// AI Transcript Generation models
class AITranscriptRequest extends Equatable {
  final String context;
  final String? customInstructions;

  const AITranscriptRequest({
    required this.context,
    this.customInstructions,
  });

  Map<String, dynamic> toJson() => {
    'context': context,
    if (customInstructions != null && customInstructions!.isNotEmpty)
      'custom_instructions': customInstructions!,
  };

  @override
  List<Object?> get props => [context, customInstructions];
}

class AITranscriptResponse extends Equatable {
  final String status;
  final String transcript;
  final int wordCount;
  final double estimatedDurationSeconds;
  final String modelUsed;
  final Map<String, dynamic> tokensUsed;
  final String contextProvided;
  final String? errorMessage;
  final String? errorType;

  const AITranscriptResponse({
    required this.status,
    this.transcript = '',
    this.wordCount = 0,
    this.estimatedDurationSeconds = 0.0,
    this.modelUsed = '',
    this.tokensUsed = const {},
    this.contextProvided = '',
    this.errorMessage,
    this.errorType,
  });

  factory AITranscriptResponse.fromJson(Map<String, dynamic> json) => AITranscriptResponse(
    status: json['status'] as String,
    transcript: json['transcript'] as String? ?? '',
    wordCount: json['word_count'] as int? ?? 0,
    estimatedDurationSeconds: (json['estimated_duration_seconds'] as num?)?.toDouble() ?? 0.0,
    modelUsed: json['model_used'] as String? ?? '',
    tokensUsed: json['tokens_used'] as Map<String, dynamic>? ?? {},
    contextProvided: json['context_provided'] as String? ?? '',
    errorMessage: json['error_message'] as String?,
    errorType: json['error_type'] as String?,
  );

  bool get isSuccess => status == 'success';
  bool get isError => status == 'error';

  @override
  List<Object?> get props => [
    status, transcript, wordCount, estimatedDurationSeconds, 
    modelUsed, tokensUsed, contextProvided, errorMessage, errorType
  ];
}

class AITranscriptValidation extends Equatable {
  final bool valid;
  final int characterCount;
  final int wordCount;
  final int estimatedTokens;
  final String? error;

  const AITranscriptValidation({
    required this.valid,
    this.characterCount = 0,
    this.wordCount = 0,
    this.estimatedTokens = 0,
    this.error,
  });

  factory AITranscriptValidation.fromJson(Map<String, dynamic> json) => AITranscriptValidation(
    valid: json['valid'] as bool,
    characterCount: json['character_count'] as int? ?? 0,
    wordCount: json['word_count'] as int? ?? 0,
    estimatedTokens: json['estimated_tokens'] as int? ?? 0,
    error: json['error'] as String?,
  );

  @override
  List<Object?> get props => [valid, characterCount, wordCount, estimatedTokens, error];
}

// S3 configuration model
class S3Configuration extends Equatable {
  final bool awsAccessKeyIdConfigured;
  final bool awsSecretAccessKeyConfigured;
  final bool s3BucketNameConfigured;
  final String awsRegion;
  final String s3BucketName;
  final bool allConfigured;
  final String s3ConnectionStatus;
  final bool s3ServiceAvailable;

  const S3Configuration({
    required this.awsAccessKeyIdConfigured,
    required this.awsSecretAccessKeyConfigured,
    required this.s3BucketNameConfigured,
    required this.awsRegion,
    required this.s3BucketName,
    required this.allConfigured,
    required this.s3ConnectionStatus,
    required this.s3ServiceAvailable,
  });

  factory S3Configuration.fromJson(Map<String, dynamic> json) => S3Configuration(
    awsAccessKeyIdConfigured: json['aws_access_key_id_configured'] as bool,
    awsSecretAccessKeyConfigured: json['aws_secret_access_key_configured'] as bool,
    s3BucketNameConfigured: json['s3_bucket_name_configured'] as bool,
    awsRegion: json['aws_region'] as String,
    s3BucketName: json['s3_bucket_name'] as String,
    allConfigured: json['all_configured'] as bool,
    s3ConnectionStatus: json['s3_connection_status'] as String,
    s3ServiceAvailable: json['s3_service_available'] as bool,
  );

  @override
  List<Object> get props => [
    awsAccessKeyIdConfigured,
    awsSecretAccessKeyConfigured,
    s3BucketNameConfigured,
    awsRegion,
    s3BucketName,
    allConfigured,
    s3ConnectionStatus,
    s3ServiceAvailable,
  ];
}

// Upload config response model
class UploadConfigResponse extends Equatable {
  final String status;
  final S3Configuration s3Configuration;
  final List<String> recommendations;

  const UploadConfigResponse({
    required this.status,
    required this.s3Configuration,
    required this.recommendations,
  });

  factory UploadConfigResponse.fromJson(Map<String, dynamic> json) => UploadConfigResponse(
    status: json['status'] as String,
    s3Configuration: S3Configuration.fromJson(json['s3_configuration']),
    recommendations: (json['recommendations'] as List<dynamic>).cast<String>(),
  );

  @override
  List<Object> get props => [status, s3Configuration, recommendations];
} 
class S3VideoModel {
  final String id;
  final String filename;
  final String s3Key;
  final String s3Url;
  final String? thumbnailUrl;
  final DateTime uploadedAt;
  final int fileSize;
  final double? duration;
  final String contentType;
  final Map<String, dynamic>? metadata;

  const S3VideoModel({
    required this.id,
    required this.filename,
    required this.s3Key,
    required this.s3Url,
    this.thumbnailUrl,
    required this.uploadedAt,
    required this.fileSize,
    this.duration,
    required this.contentType,
    this.metadata,
  });

  factory S3VideoModel.fromJson(Map<String, dynamic> json) {
    return S3VideoModel(
      id: json['id'] as String,
      filename: json['original_filename'] as String? ?? json['filename'] as String,
      s3Key: json['s3_key'] as String,
      s3Url: json['s3_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      uploadedAt: DateTime.parse(json['created_at'] as String? ?? json['uploaded_at'] as String),
      fileSize: json['file_size'] as int,
      duration: json['duration']?.toDouble(),
      contentType: json['content_type'] as String,
      metadata: json['video_metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filename': filename,
      's3_key': s3Key,
      's3_url': s3Url,
      'thumbnail_url': thumbnailUrl,
      'uploaded_at': uploadedAt.toIso8601String(),
      'file_size': fileSize,
      'duration': duration,
      'content_type': contentType,
      'metadata': metadata,
    };
  }
}

class S3VideoListResponse {
  final List<S3VideoModel> videos;
  final int totalCount;
  final int page;
  final int pageSize;
  final bool hasMore;

  const S3VideoListResponse({
    required this.videos,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  factory S3VideoListResponse.fromJson(Map<String, dynamic> json) {
    return S3VideoListResponse(
      videos: (json['videos'] as List)
          .map((video) => S3VideoModel.fromJson(video as Map<String, dynamic>))
          .toList(),
      totalCount: json['total_count'] as int,
      page: json['page'] as int,
      pageSize: json['page_size'] as int,
      hasMore: json['has_more'] as bool,
    );
  }
} 
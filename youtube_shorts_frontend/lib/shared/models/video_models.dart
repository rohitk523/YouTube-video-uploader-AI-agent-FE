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

class YouTubeVideoModel {
  final String id;
  final String title;
  final String description;
  final String? thumbnailUrl;
  final String? duration; // ISO 8601 format (PT1M30S)
  final DateTime? publishedAt;
  final int? viewCount;
  final int? likeCount;
  final String privacyStatus; // public, unlisted, private
  final bool isInS3; // Whether this video is already in our S3 storage
  final String? s3VideoId; // Reference to S3VideoModel if exists
  final Map<String, dynamic>? metadata;

  const YouTubeVideoModel({
    required this.id,
    required this.title,
    required this.description,
    this.thumbnailUrl,
    this.duration,
    this.publishedAt,
    this.viewCount,
    this.likeCount,
    required this.privacyStatus,
    this.isInS3 = false,
    this.s3VideoId,
    this.metadata,
  });

  factory YouTubeVideoModel.fromJson(Map<String, dynamic> json) {
    return YouTubeVideoModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String?,
      duration: json['duration'] as String?,
      publishedAt: json['published_at'] != null 
          ? DateTime.parse(json['published_at'] as String)
          : null,
      viewCount: json['view_count'] as int?,
      likeCount: json['like_count'] as int?,
      privacyStatus: json['privacy_status'] as String? ?? 'public',
      isInS3: json['is_in_s3'] as bool? ?? false,
      s3VideoId: json['s3_video_id'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnail_url': thumbnailUrl,
      'duration': duration,
      'published_at': publishedAt?.toIso8601String(),
      'view_count': viewCount,
      'like_count': likeCount,
      'privacy_status': privacyStatus,
      'is_in_s3': isInS3,
      's3_video_id': s3VideoId,
      'metadata': metadata,
    };
  }

  YouTubeVideoModel copyWith({
    String? id,
    String? title,
    String? description,
    String? thumbnailUrl,
    String? duration,
    DateTime? publishedAt,
    int? viewCount,
    int? likeCount,
    String? privacyStatus,
    bool? isInS3,
    String? s3VideoId,
    Map<String, dynamic>? metadata,
  }) {
    return YouTubeVideoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      publishedAt: publishedAt ?? this.publishedAt,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      privacyStatus: privacyStatus ?? this.privacyStatus,
      isInS3: isInS3 ?? this.isInS3,
      s3VideoId: s3VideoId ?? this.s3VideoId,
      metadata: metadata ?? this.metadata,
    );
  }
}

class YouTubeVideosListResponse {
  final List<YouTubeVideoModel> videos;
  final int totalCount;
  final int page;
  final int pageSize;
  final bool hasMore;
  final String? nextPageToken;

  const YouTubeVideosListResponse({
    required this.videos,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.hasMore,
    this.nextPageToken,
  });

  factory YouTubeVideosListResponse.fromJson(Map<String, dynamic> json) {
    return YouTubeVideosListResponse(
      videos: (json['videos'] as List)
          .map((video) => YouTubeVideoModel.fromJson(video as Map<String, dynamic>))
          .toList(),
      totalCount: json['total_count'] as int,
      page: json['page'] as int,
      pageSize: json['page_size'] as int,
      hasMore: json['has_more'] as bool,
      nextPageToken: json['next_page_token'] as String?,
    );
  }
}

class AddVideoToS3Response {
  final bool success;
  final String message;
  final String? s3VideoId;
  final String? s3Key;
  final String? downloadUrl;
  final Map<String, dynamic>? processingInfo;

  const AddVideoToS3Response({
    required this.success,
    required this.message,
    this.s3VideoId,
    this.s3Key,
    this.downloadUrl,
    this.processingInfo,
  });

  factory AddVideoToS3Response.fromJson(Map<String, dynamic> json) {
    return AddVideoToS3Response(
      success: json['success'] as bool,
      message: json['message'] as String,
      s3VideoId: json['s3_video_id'] as String?,
      s3Key: json['s3_key'] as String?,
      downloadUrl: json['download_url'] as String?,
      processingInfo: json['processing_info'] as Map<String, dynamic>?,
    );
  }
} 
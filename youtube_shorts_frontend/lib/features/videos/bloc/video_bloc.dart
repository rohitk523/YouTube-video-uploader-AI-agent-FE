import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../shared/models/video_models.dart';
import '../repository/video_repository.dart';

// Events
abstract class VideoEvent extends Equatable {
  const VideoEvent();

  @override
  List<Object?> get props => [];
}

class LoadRecentVideos extends VideoEvent {
  final int limit;

  const LoadRecentVideos({this.limit = 5});

  @override
  List<Object?> get props => [limit];
}

class LoadS3Videos extends VideoEvent {
  final int page;
  final int pageSize;
  final String? search;
  final bool refresh;

  const LoadS3Videos({
    this.page = 1,
    this.pageSize = 10,
    this.search,
    this.refresh = false,
  });

  @override
  List<Object?> get props => [page, pageSize, search, refresh];
}

class LoadMoreVideos extends VideoEvent {}

class SearchVideos extends VideoEvent {
  final String query;

  const SearchVideos(this.query);

  @override
  List<Object?> get props => [query];
}

class RefreshVideos extends VideoEvent {}

// YouTube Events
class LoadYouTubeVideosEvent extends VideoEvent {
  final int page;
  final int pageSize;
  final String? nextPageToken;

  const LoadYouTubeVideosEvent({
    this.page = 1,
    this.pageSize = 20,
    this.nextPageToken,
  });

  @override
  List<Object?> get props => [page, pageSize, nextPageToken];
}

class LoadMoreYouTubeVideosEvent extends VideoEvent {}

class RefreshYouTubeVideosEvent extends VideoEvent {}

class AddYouTubeVideoToS3Event extends VideoEvent {
  final YouTubeVideoModel video;

  const AddYouTubeVideoToS3Event(this.video);

  @override
  List<Object?> get props => [video];
}

class SyncAllYouTubeVideosToS3Event extends VideoEvent {}

// States
abstract class VideoState extends Equatable {
  const VideoState();

  @override
  List<Object?> get props => [];
}

class VideoInitial extends VideoState {}

class VideoLoading extends VideoState {}

class RecentVideosLoaded extends VideoState {
  final List<S3VideoModel> videos;

  const RecentVideosLoaded(this.videos);

  @override
  List<Object?> get props => [videos];
}

class S3VideosLoaded extends VideoState {
  final List<S3VideoModel> videos;
  final bool hasMore;
  final int currentPage;
  final bool isLoadingMore;

  const S3VideosLoaded({
    required this.videos,
    required this.hasMore,
    required this.currentPage,
    this.isLoadingMore = false,
  });

  @override
  List<Object?> get props => [videos, hasMore, currentPage, isLoadingMore];

  S3VideosLoaded copyWith({
    List<S3VideoModel>? videos,
    bool? hasMore,
    int? currentPage,
    bool? isLoadingMore,
  }) {
    return S3VideosLoaded(
      videos: videos ?? this.videos,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

// YouTube States
class YouTubeVideosLoaded extends VideoState {
  final List<YouTubeVideoModel> videos;
  final bool hasMore;
  final int currentPage;
  final bool isLoadingMore;
  final String? nextPageToken;

  const YouTubeVideosLoaded({
    required this.videos,
    required this.hasMore,
    required this.currentPage,
    this.isLoadingMore = false,
    this.nextPageToken,
  });

  @override
  List<Object?> get props => [videos, hasMore, currentPage, isLoadingMore, nextPageToken];

  YouTubeVideosLoaded copyWith({
    List<YouTubeVideoModel>? videos,
    bool? hasMore,
    int? currentPage,
    bool? isLoadingMore,
    String? nextPageToken,
  }) {
    return YouTubeVideosLoaded(
      videos: videos ?? this.videos,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      nextPageToken: nextPageToken ?? this.nextPageToken,
    );
  }
}

class YouTubeVideoAddedToS3 extends VideoState {
  final String videoTitle;
  final String s3VideoId;

  const YouTubeVideoAddedToS3({
    required this.videoTitle,
    required this.s3VideoId,
  });

  @override
  List<Object?> get props => [videoTitle, s3VideoId];
}

class YouTubeVideoSyncInProgress extends VideoState {
  final String videoTitle;
  final String progress;

  const YouTubeVideoSyncInProgress({
    required this.videoTitle,
    required this.progress,
  });

  @override
  List<Object?> get props => [videoTitle, progress];
}

class VideoError extends VideoState {
  final String message;

  const VideoError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class VideoBloc extends Bloc<VideoEvent, VideoState> {
  final VideoRepository _videoRepository;

  VideoBloc(this._videoRepository) : super(VideoInitial()) {
    on<LoadRecentVideos>(_onLoadRecentVideos);
    on<LoadS3Videos>(_onLoadS3Videos);
    on<LoadMoreVideos>(_onLoadMoreVideos);
    on<SearchVideos>(_onSearchVideos);
    on<RefreshVideos>(_onRefreshVideos);
    
    // YouTube event handlers
    on<LoadYouTubeVideosEvent>(_onLoadYouTubeVideos);
    on<LoadMoreYouTubeVideosEvent>(_onLoadMoreYouTubeVideos);
    on<RefreshYouTubeVideosEvent>(_onRefreshYouTubeVideos);
    on<AddYouTubeVideoToS3Event>(_onAddYouTubeVideoToS3);
    on<SyncAllYouTubeVideosToS3Event>(_onSyncAllYouTubeVideosToS3);
  }

  Future<void> _onLoadRecentVideos(
    LoadRecentVideos event,
    Emitter<VideoState> emit,
  ) async {
    try {
      emit(VideoLoading());
      final videos = await _videoRepository.getRecentVideos(limit: event.limit);
      emit(RecentVideosLoaded(videos));
    } catch (e) {
      emit(VideoError(e.toString()));
    }
  }

  Future<void> _onLoadS3Videos(
    LoadS3Videos event,
    Emitter<VideoState> emit,
  ) async {
    try {
      if (event.refresh || state is! S3VideosLoaded) {
        emit(VideoLoading());
      }

      final response = await _videoRepository.getS3Videos(
        page: event.page,
        pageSize: event.pageSize,
        search: event.search,
      );

      emit(S3VideosLoaded(
        videos: response.videos,
        hasMore: response.hasMore,
        currentPage: response.page,
      ));
    } catch (e) {
      emit(VideoError(e.toString()));
    }
  }

  Future<void> _onLoadMoreVideos(
    LoadMoreVideos event,
    Emitter<VideoState> emit,
  ) async {
    final currentState = state;
    if (currentState is S3VideosLoaded && currentState.hasMore && !currentState.isLoadingMore) {
      try {
        emit(currentState.copyWith(isLoadingMore: true));

        final response = await _videoRepository.getS3Videos(
          page: currentState.currentPage + 1,
          pageSize: 10,
        );

        emit(S3VideosLoaded(
          videos: [...currentState.videos, ...response.videos],
          hasMore: response.hasMore,
          currentPage: response.page,
          isLoadingMore: false,
        ));
      } catch (e) {
        emit(currentState.copyWith(isLoadingMore: false));
        emit(VideoError(e.toString()));
      }
    }
  }

  Future<void> _onSearchVideos(
    SearchVideos event,
    Emitter<VideoState> emit,
  ) async {
    add(LoadS3Videos(search: event.query, refresh: true));
  }

  Future<void> _onRefreshVideos(
    RefreshVideos event,
    Emitter<VideoState> emit,
  ) async {
    add(const LoadS3Videos(refresh: true));
  }

  // YouTube event handlers
  Future<void> _onLoadYouTubeVideos(
    LoadYouTubeVideosEvent event,
    Emitter<VideoState> emit,
  ) async {
    try {
      emit(VideoLoading());
      final response = await _videoRepository.getYouTubeVideos(
        page: event.page,
        pageSize: event.pageSize,
        nextPageToken: event.nextPageToken,
      );

      emit(YouTubeVideosLoaded(
        videos: response.videos,
        hasMore: response.hasMore,
        currentPage: response.page,
        nextPageToken: response.nextPageToken,
      ));
    } catch (e) {
      emit(VideoError('Failed to load YouTube videos: ${e.toString()}'));
    }
  }

  Future<void> _onLoadMoreYouTubeVideos(
    LoadMoreYouTubeVideosEvent event,
    Emitter<VideoState> emit,
  ) async {
    final currentState = state;
    if (currentState is YouTubeVideosLoaded && 
        currentState.hasMore && 
        !currentState.isLoadingMore) {
      try {
        emit(currentState.copyWith(isLoadingMore: true));

        final response = await _videoRepository.getYouTubeVideos(
          page: currentState.currentPage + 1,
          pageSize: 20,
          nextPageToken: currentState.nextPageToken,
        );

        emit(YouTubeVideosLoaded(
          videos: [...currentState.videos, ...response.videos],
          hasMore: response.hasMore,
          currentPage: response.page,
          isLoadingMore: false,
          nextPageToken: response.nextPageToken,
        ));
      } catch (e) {
        emit(currentState.copyWith(isLoadingMore: false));
        emit(VideoError('Failed to load more YouTube videos: ${e.toString()}'));
      }
    }
  }

  Future<void> _onRefreshYouTubeVideos(
    RefreshYouTubeVideosEvent event,
    Emitter<VideoState> emit,
  ) async {
    add(const LoadYouTubeVideosEvent());
  }

  Future<void> _onAddYouTubeVideoToS3(
    AddYouTubeVideoToS3Event event,
    Emitter<VideoState> emit,
  ) async {
    try {
      emit(YouTubeVideoSyncInProgress(
        videoTitle: event.video.title,
        progress: 'Starting download...',
      ));

      final response = await _videoRepository.addYouTubeVideoToS3(event.video.id);

      emit(YouTubeVideoAddedToS3(
        videoTitle: event.video.title,
        s3VideoId: response.s3VideoId!,
      ));

      // Refresh the YouTube videos list to update the status
      add(const LoadYouTubeVideosEvent());
      
    } catch (e) {
      emit(VideoError('Failed to add video to S3: ${e.toString()}'));
    }
  }

  Future<void> _onSyncAllYouTubeVideosToS3(
    SyncAllYouTubeVideosToS3Event event,
    Emitter<VideoState> emit,
  ) async {
    final currentState = state;
    if (currentState is YouTubeVideosLoaded) {
      try {
        emit(YouTubeVideoSyncInProgress(
          videoTitle: 'All Videos',
          progress: 'Starting sync of all videos...',
        ));

        await _videoRepository.syncAllYouTubeVideosToS3();

        emit(YouTubeVideoAddedToS3(
          videoTitle: 'All Videos',
          s3VideoId: 'multiple',
        ));

        // Refresh the YouTube videos list to update statuses
        add(const LoadYouTubeVideosEvent());
        
      } catch (e) {
        emit(VideoError('Failed to sync all videos: ${e.toString()}'));
      }
    }
  }
} 
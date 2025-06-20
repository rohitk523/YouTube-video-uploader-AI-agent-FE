import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../shared/models/video_models.dart';
import '../bloc/video_bloc.dart';

class YouTubeVideosListScreen extends StatefulWidget {
  const YouTubeVideosListScreen({super.key});

  @override
  State<YouTubeVideosListScreen> createState() => _YouTubeVideosListScreenState();
}

class _YouTubeVideosListScreenState extends State<YouTubeVideosListScreen> {
  final _scrollController = ScrollController();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Load YouTube videos on init
    context.read<VideoBloc>().add(LoadYouTubeVideosEvent());
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        context.read<VideoBloc>().add(LoadMoreYouTubeVideosEvent());
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My YouTube Videos'),
        elevation: 2,
        actions: [
          IconButton(
            onPressed: _refreshVideos,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh videos',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'sync_all':
                  _showSyncAllDialog();
                  break;
                case 'help':
                  _showHelpDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'sync_all',
                child: Row(
                  children: [
                    Icon(Icons.sync),
                    SizedBox(width: 8),
                    Text('Sync All to S3'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'help',
                child: Row(
                  children: [
                    Icon(Icons.help_outline),
                    SizedBox(width: 8),
                    Text('Help'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: BlocConsumer<VideoBloc, VideoState>(
        listener: (context, state) {
          if (state is VideoError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'Retry',
                  onPressed: () {
                    context.read<VideoBloc>().add(LoadYouTubeVideosEvent());
                  },
                ),
              ),
            );
          } else if (state is YouTubeVideoAddedToS3) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('${state.videoTitle} added to S3 successfully!'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is VideoLoading && !_isRefreshing) {
            return _buildLoadingState();
          } else if (state is YouTubeVideosLoaded) {
            return _buildVideosGrid(state.videos, state.isLoadingMore);
          } else if (state is VideoError) {
            return _buildErrorState(state.message);
          } else {
            return _buildEmptyState();
          }
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading your YouTube videos...'),
          SizedBox(height: 8),
          Text(
            'This may take a moment while we fetch your videos',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildVideosGrid(List<YouTubeVideoModel> videos, bool isLoadingMore) {
    if (videos.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshVideos,
      child: Column(
        children: [
          // Header info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Found ${videos.length} videos in your YouTube channel. Select videos to add to your S3 storage.',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ),
          
          // Videos grid
          Expanded(
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: videos.length + (isLoadingMore ? 2 : 0),
              itemBuilder: (context, index) {
                if (index >= videos.length) {
                  return _buildLoadingCard();
                }
                return _buildVideoCard(videos[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(YouTubeVideoModel video) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Video thumbnail
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.grey.shade200,
                  child: video.thumbnailUrl != null
                      ? Image.network(
                          video.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.video_library, size: 48);
                          },
                        )
                      : const Icon(Icons.video_library, size: 48),
                ),
                
                // Duration overlay
                if (video.duration != null)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatDuration(video.duration!),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                
                // Status indicator
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: video.isInS3 
                          ? Colors.green.withOpacity(0.9) 
                          : Colors.orange.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          video.isInS3 ? Icons.cloud_done : Icons.cloud_upload,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          video.isInS3 ? 'In S3' : 'YouTube',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Video info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  Row(
                    children: [
                      Icon(Icons.visibility, size: 12, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        _formatViews(video.viewCount ?? 0),
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      ),
                      const Spacer(),
                      if (video.publishedAt != null) ...[
                        Text(
                          _formatDate(video.publishedAt!),
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                        ),
                      ],
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: video.isInS3 
                          ? null 
                          : () => _addVideoToS3(video),
                      icon: Icon(
                        video.isInS3 ? Icons.check : Icons.cloud_upload,
                        size: 16,
                      ),
                      label: Text(
                        video.isInS3 ? 'In S3' : 'Add to S3',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: video.isInS3 
                            ? Colors.green 
                            : Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        minimumSize: const Size(0, 28),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: 8),
            Text('Loading...', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No YouTube Videos Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Make sure you have videos on your YouTube channel\nand proper permissions are configured.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshVideos,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Videos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<VideoBloc>().add(LoadYouTubeVideosEvent());
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshVideos() async {
    setState(() {
      _isRefreshing = true;
    });
    
    context.read<VideoBloc>().add(RefreshYouTubeVideosEvent());
    
    // Wait a bit for the refresh
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  void _addVideoToS3(YouTubeVideoModel video) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Video to S3'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add "${video.title}" to your S3 storage?'),
            const SizedBox(height: 16),
            const Text(
              'This will download the video from YouTube and upload it to your S3 bucket for use in creating shorts.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<VideoBloc>().add(AddYouTubeVideoToS3Event(video));
            },
            child: const Text('Add to S3'),
          ),
        ],
      ),
    );
  }

  void _showSyncAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync All Videos'),
        content: const Text(
          'This will add all YouTube videos that are not already in S3 to your S3 storage. This may take some time and consume storage space.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<VideoBloc>().add(SyncAllYouTubeVideosToS3Event());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Sync All'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('YouTube Videos Help'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This page shows videos from your YouTube channel that you can add to your S3 storage for creating shorts.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            Text(
              '• Videos marked "In S3" are already available for shorts creation',
              style: TextStyle(fontSize: 14),
            ),
            Text(
              '• Videos marked "YouTube" can be added to S3 storage',
              style: TextStyle(fontSize: 14),
            ),
            Text(
              '• Use "Add to S3" to download and store individual videos',
              style: TextStyle(fontSize: 14),
            ),
            Text(
              '• Use "Sync All" to add all videos to S3 at once',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(String duration) {
    // Parse ISO 8601 duration format (PT1M30S) to MM:SS
    final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
    final match = regex.firstMatch(duration);
    
    if (match != null) {
      final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
      final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
      final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;
      
      if (hours > 0) {
        return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      } else {
        return '${minutes}:${seconds.toString().padLeft(2, '0')}';
      }
    }
    
    return '0:00';
  }

  String _formatViews(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    } else {
      return views.toString();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'Today';
    }
  }
} 
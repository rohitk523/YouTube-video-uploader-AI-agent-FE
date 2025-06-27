import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../../../shared/models/video_models.dart';
import '../bloc/video_bloc.dart';
import '../../../core/network/api_client.dart';
import '../../upload/bloc/upload_bloc.dart';
import '../../upload/bloc/upload_event.dart';
import '../../upload/bloc/upload_state.dart';

class VideoSelectionWidget extends StatefulWidget {
  final S3VideoModel? selectedVideo;
  final Function(S3VideoModel?) onVideoSelected;
  final VoidCallback onUploadNewVideo;
  final bool showUploadButton;

  const VideoSelectionWidget({
    super.key,
    this.selectedVideo,
    required this.onVideoSelected,
    required this.onUploadNewVideo,
    this.showUploadButton = true,
  });

  @override
  State<VideoSelectionWidget> createState() => _VideoSelectionWidgetState();
}

class _VideoSelectionWidgetState extends State<VideoSelectionWidget> {
  bool _openHoveringUploadBox = false;
  File? _selectedVideoFile;
  PlatformFile? _selectedVideoPlatformFile;

  @override
  void initState() {
    super.initState();
    context.read<VideoBloc>().add(const LoadRecentVideos());
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Select Video', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _showAllVideosDialog(context),
                      icon: const Icon(Icons.library_music),
                      label: const Text('Browse All'),
                    ),
                    const SizedBox(width: 8),
                    // Floating Upload Button
                    ElevatedButton.icon(
                      onPressed: () => _showHoveringUploadBox(),
                      icon: const Icon(Icons.cloud_upload, size: 18),
                      label: const Text('Quick Upload'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        elevation: 4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Recent Videos', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey)),
                const SizedBox(height: 8),
                BlocBuilder<VideoBloc, VideoState>(
                  builder: (context, state) {
                    if (state is VideoLoading) {
                      return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator()));
                    }
                    if (state is RecentVideosLoaded) {
                      return _buildRecentVideosGrid(state.videos);
                    }
                    if (state is VideoError) {
                      return _buildErrorWidget(state.message);
                    }
                    return _buildEmptyState();
                  },
                ),
                if (widget.showUploadButton) ...[
                  const SizedBox(height: 16),
                  _buildUploadButton(),
                ],
              ],
            ),
          ),
        ),
        // Hovering Upload Box Overlay
        if (_openHoveringUploadBox) _buildHoveringUploadBox(),
      ],
    );
  }

  Widget _buildHoveringUploadBox() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(32),
            elevation: 16,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 400),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(Icons.cloud_upload, color: Colors.blue.shade600, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Quick Video Upload',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => setState(() => _openHoveringUploadBox = false),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Upload Area
                  if (_selectedVideoPlatformFile == null) ...[
                    _buildUploadDropZone(),
                  ] else ...[
                    _buildSelectedFileDisplay(),
                    const SizedBox(height: 16),
                    _buildUploadActions(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadDropZone() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.blue.shade300,
          width: 2,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(12),
        color: Colors.blue.shade50,
      ),
      child: InkWell(
        onTap: _pickVideoFile,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_call,
              size: 64,
              color: Colors.blue.shade600,
            ),
            const SizedBox(height: 16),
            Text(
              'Tap to select video file',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Supported formats: MP4, MOV, AVI',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Choose File',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFileDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.video_file, color: Colors.green.shade600, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedVideoPlatformFile!.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(_selectedVideoPlatformFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() {
                  _selectedVideoPlatformFile = null;
                  _selectedVideoFile = null;
                }),
                icon: Icon(Icons.close, color: Colors.red.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadActions() {
    return BlocConsumer<UploadBloc, UploadState>(
      listener: (context, state) {
        if (state is VideoUploadSuccess) {
          setState(() {
            _openHoveringUploadBox = false;
            _selectedVideoPlatformFile = null;
            _selectedVideoFile = null;
          });
          
          // Refresh recent videos to show the newly uploaded video
          context.read<VideoBloc>().add(const LoadRecentVideos());
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text('Video uploaded successfully! It will appear in recent videos.'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (state is UploadError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is UploadProgress) {
          return Column(
            children: [
              LinearProgressIndicator(
                value: state.progress,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                state.message ?? 'Uploading video...',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          );
        }
        
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() {
                  _selectedVideoPlatformFile = null;
                  _selectedVideoFile = null;
                }),
                child: const Text('Change File'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _uploadSelectedVideo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Upload Now'),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickVideoFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );
    
    if (result != null && result.files.isNotEmpty) {
      final platformFile = result.files.first;
      setState(() {
        _selectedVideoPlatformFile = platformFile;
        // For non-web platforms, still create File object
        if (!kIsWeb && platformFile.path != null) {
          _selectedVideoFile = File(platformFile.path!);
        }
      });
    }
  }

  void _uploadSelectedVideo() {
    if (_selectedVideoPlatformFile != null) {
      if (kIsWeb) {
        // For web, use platform file with is_temp=false to appear in recent videos
        context.read<UploadBloc>().add(
          UploadVideoEvent(
            videoFile: null,
            title: _selectedVideoPlatformFile!.name.replaceAll(RegExp(r'\.[^.]*$'), ''), // Remove extension for title
            description: 'Uploaded via Quick Upload',
            platformFile: _selectedVideoPlatformFile!,
            isTemp: false, // Set to false so video appears in recent videos
          ),
        );
      } else if (_selectedVideoFile != null) {
        // For mobile, use File object with is_temp=false to appear in recent videos
        context.read<UploadBloc>().add(
          UploadVideoEvent(
            videoFile: _selectedVideoFile!,
            title: _selectedVideoPlatformFile!.name.replaceAll(RegExp(r'\.[^.]*$'), ''), // Remove extension for title
            description: 'Uploaded via Quick Upload',
            isTemp: false, // Set to false so video appears in recent videos
          ),
        );
      }
    }
  }

  void _showHoveringUploadBox() {
    setState(() {
      _openHoveringUploadBox = true;
      _selectedVideoPlatformFile = null;
      _selectedVideoFile = null;
    });
  }

  Widget _buildRecentVideosGrid(List<S3VideoModel> videos) {
    if (videos.isEmpty) return _buildEmptyState();

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: videos.length,
        itemBuilder: (context, index) => _buildVideoTile(videos[index]),
      ),
    );
  }

  Widget _buildVideoTile(S3VideoModel video) {
    final isSelected = widget.selectedVideo?.id == video.id;
    
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () => widget.onVideoSelected(video),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                      child: Container(
                        width: double.infinity,
                        color: Colors.grey.shade200,
                        child: video.thumbnailUrl != null
                            ? Image.network(
                                video.thumbnailUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.video_file);
                                },
                              )
                            : const Icon(Icons.video_file),
                      ),
                    ),
                    // Duration overlay - prominent display
                    if (video.duration != null)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _formatDuration(Duration(seconds: video.duration!.toInt())),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.filename, 
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _formatFileSize(video.fileSize), 
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600)
                          ),
                        ),
                        if (video.duration != null) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.play_circle_outline, size: 10, color: Colors.grey.shade600),
                          const SizedBox(width: 2),
                          Text(
                            _formatDuration(Duration(seconds: video.duration!.toInt())),
                            style: TextStyle(
                              fontSize: 10, 
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade300, width: 2),
        borderRadius: BorderRadius.circular(12),
        color: Colors.blue.shade50,
      ),
      child: InkWell(
        onTap: widget.onUploadNewVideo,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 32, color: Colors.blue.shade600),
            const SizedBox(height: 4),
            Text('Upload New Video', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library_outlined, size: 32, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text('No recent videos found', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400),
          const SizedBox(height: 8),
          Text('Failed to load videos', style: TextStyle(color: Colors.red.shade600)),
          TextButton(
            onPressed: () => context.read<VideoBloc>().add(const LoadRecentVideos()),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showAllVideosDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => BlocProvider.value(
        value: context.read<VideoBloc>(),
        child: VideoLibraryDialog(
          onVideoSelected: widget.onVideoSelected,
          selectedVideoId: widget.selectedVideo?.id,
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      final hours = twoDigits(duration.inHours);
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

class VideoLibraryDialog extends StatefulWidget {
  final Function(S3VideoModel?) onVideoSelected;
  final String? selectedVideoId;

  const VideoLibraryDialog({super.key, required this.onVideoSelected, this.selectedVideoId});

  @override
  State<VideoLibraryDialog> createState() => _VideoLibraryDialogState();
}

class _VideoLibraryDialogState extends State<VideoLibraryDialog> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<VideoBloc>().add(const LoadS3Videos());
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                const Text('Video Library', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search videos...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onSubmitted: (query) => context.read<VideoBloc>().add(SearchVideos(query)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<VideoBloc, VideoState>(
                builder: (context, state) {
                  if (state is VideoLoading) return const Center(child: CircularProgressIndicator());
                  if (state is S3VideosLoaded) return _buildVideoGrid(state.videos);
                  if (state is VideoError) return _buildErrorState(state.message);
                  return const Center(child: Text('No videos found'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoGrid(List<S3VideoModel> videos) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.8),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        final isSelected = widget.selectedVideoId == video.id;
        
        return InkWell(
          onTap: () {
            widget.onVideoSelected(video);
            Navigator.of(context).pop();
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300, width: isSelected ? 2 : 1),
            ),
            child: Column(
              children: [
                Expanded(
                  flex: 3, 
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                          child: video.thumbnailUrl != null
                              ? Image.network(
                                  video.thumbnailUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.video_file);
                                  },
                                )
                              : const Icon(Icons.video_file),
                        ),
                      ),
                      // Duration overlay
                      if (video.duration != null)
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _formatDuration(Duration(seconds: video.duration!.toInt())),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(video.filename, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Expanded(
                              child: Text(_formatFileSize(video.fileSize), style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                            ),
                            if (video.duration != null) ...[
                              Icon(Icons.schedule, size: 10, color: Colors.grey.shade600),
                              const SizedBox(width: 2),
                              Text(
                                _formatDuration(Duration(seconds: video.duration!.toInt())),
                                style: TextStyle(
                                  fontSize: 10, 
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(message),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.read<VideoBloc>().add(const LoadS3Videos()),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      final hours = twoDigits(duration.inHours);
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
} 
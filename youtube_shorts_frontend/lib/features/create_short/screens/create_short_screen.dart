import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html;
import '../../../core/constants/api_constants.dart';
import '../../../shared/models/upload_models.dart';
import '../../../shared/models/job_models.dart';
import '../../../shared/models/video_models.dart';
import '../../../shared/widgets/video_preview_widget.dart';
import '../../upload/bloc/upload_bloc.dart';
import '../../upload/bloc/upload_event.dart';
import '../../upload/bloc/upload_state.dart';
import '../../jobs/bloc/jobs_bloc.dart';
import '../../jobs/bloc/jobs_event.dart';
import '../../jobs/bloc/jobs_state.dart';
import '../../videos/widgets/video_selection_widget.dart';
import '../widgets/voice_preview_widget.dart';

class CreateShortScreen extends StatefulWidget {
  final bool showAppBar;
  
  const CreateShortScreen({super.key, this.showAppBar = true});

  @override
  State<CreateShortScreen> createState() => _CreateShortScreenState();
}

class _CreateShortScreenState extends State<CreateShortScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _transcriptController = TextEditingController();
  
  File? _selectedVideoFile;
  File? _selectedTranscriptFile;
  PlatformFile? _selectedVideoPlatformFile;
  PlatformFile? _selectedTranscriptPlatformFile;
  UploadResponse? _videoUploadResponse;
  UploadResponse? _transcriptUploadResponse;
  S3VideoModel? _selectedS3Video;
  bool _showUploadSection = false;
  
  bool _isTranscriptFromText = true;
  bool _autoUploadToYoutube = false;
  bool _mockMode = false;
  String? _selectedVoice = 'alloy';
  
  final List<String> _availableVoices = [
    'alloy', 'echo', 'fable', 'onyx', 'nova', 'shimmer'
  ];

  @override
  void initState() {
    super.initState();
    // Add listener to transcript controller to update UI reactively
    _transcriptController.addListener(() {
      setState(() {
        // This will trigger a rebuild when the text changes
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _transcriptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isWeb(context) ? Theme.of(context).scaffoldBackgroundColor : null,
      appBar: (!widget.showAppBar || _isWeb(context)) ? null : AppBar(
        title: const Text('Create YouTube Short'),
      ),
      body: BlocListener<JobsBloc, JobsState>(
        listener: (context, state) {
          if (state is JobCreated) {
            _showSuccessDialog(state.job);
          } else if (state is JobsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error creating job: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocListener<UploadBloc, UploadState>(
          listener: (context, state) {
            if (state is VideoUploadSuccess) {
              setState(() {
                _videoUploadResponse = state.uploadResponse;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Video uploaded successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is TranscriptUploadSuccess) {
              setState(() {
                _transcriptUploadResponse = state.uploadResponse;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transcript uploaded successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is UploadError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Upload error: ${state.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: _isWeb(context) ? _buildWebLayout() : _buildMobileLayout(),
        ),
      ),
    );
  }

  bool _isWeb(BuildContext context) {
    return MediaQuery.of(context).size.width > 768;
  }

  Widget _buildWebLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compact Step Cards
            _buildCompactStepCard(
              stepNumber: 1,
              title: 'Video Details',
              child: _buildDetailsSection(),
            ),
            const SizedBox(height: 16),
            _buildCompactStepCard(
              stepNumber: 2,
              title: 'Select Your Video',
              child: _buildVideoSection(),
            ),
            const SizedBox(height: 16),
            _buildCompactStepCard(
              stepNumber: 3,
              title: 'Add Your Script',
              child: _buildTranscriptSection(),
            ),
            const SizedBox(height: 16),
            _buildCompactStepCard(
              stepNumber: 4,
              title: 'Advanced Options',
              child: _buildOptionsSection(),
            ),
            const SizedBox(height: 24),
            
            // Creation Status Section (Inline)
            _buildCompactStatusSection(),
            
            const SizedBox(height: 24),
            
            // Video Preview (if video selected)
            if (_selectedS3Video != null || _videoUploadResponse != null)
              _buildCompactVideoPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDetailsSection(),
            const SizedBox(height: 24),
            _buildVideoSection(),
            const SizedBox(height: 24),
            _buildTranscriptSection(),
            const SizedBox(height: 24),
            _buildOptionsSection(),
            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStepCard({
    required int stepNumber,
    required String title,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.all(0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      stepNumber.toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStatusSection() {
    final hasVideo = _videoUploadResponse != null || _selectedS3Video != null;
    final hasTranscript = _isTranscriptFromText 
        ? _transcriptController.text.trim().isNotEmpty
        : _transcriptUploadResponse != null;
    
    return Card(
      margin: const EdgeInsets.all(0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Creation Status',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildCompactStatusItem(
                    icon: hasVideo ? Icons.check_circle : Icons.video_file,
                    label: 'Video',
                    isReady: hasVideo,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCompactStatusItem(
                    icon: hasTranscript ? Icons.check_circle : Icons.text_fields,
                    label: 'Script',
                    isReady: hasTranscript,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCompactStatusItem(
                    icon: _titleController.text.isNotEmpty ? Icons.check_circle : Icons.title,
                    label: 'Title',
                    isReady: _titleController.text.isNotEmpty,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: _buildWebActionButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStatusItem({
    required IconData icon,
    required String label,
    required bool isReady,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isReady 
          ? const Color(0xFF059669).withOpacity(0.1)
          : const Color(0xFFD97706).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isReady 
            ? const Color(0xFF059669).withOpacity(0.3)
            : const Color(0xFFD97706).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isReady ? const Color(0xFF059669) : const Color(0xFFD97706),
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isReady ? const Color(0xFF059669) : const Color(0xFFD97706),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            isReady ? 'Ready' : 'Required',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactVideoPreview() {
    return Card(
      margin: const EdgeInsets.all(0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Video Preview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildVideoPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildWebStatusIndicators() {
    final hasVideo = _videoUploadResponse != null || _selectedS3Video != null;
    final hasTranscript = _isTranscriptFromText 
        ? _transcriptController.text.trim().isNotEmpty
        : _transcriptUploadResponse != null;
    
    return Column(
      children: [
        _buildWebStatusItem(
          icon: hasVideo ? Icons.check_circle : Icons.video_file,
          label: 'Video',
          status: hasVideo ? 'Ready' : 'Required',
          isReady: hasVideo,
        ),
        const SizedBox(height: 16),
        _buildWebStatusItem(
          icon: hasTranscript ? Icons.check_circle : Icons.text_fields,
          label: 'Script',
          status: hasTranscript ? 'Ready' : 'Required',
          isReady: hasTranscript,
        ),
        const SizedBox(height: 16),
        _buildWebStatusItem(
          icon: _titleController.text.isNotEmpty ? Icons.check_circle : Icons.title,
          label: 'Title',
          status: _titleController.text.isNotEmpty ? 'Ready' : 'Required',
          isReady: _titleController.text.isNotEmpty,
        ),
      ],
    );
  }

  Widget _buildWebStatusItem({
    required IconData icon,
    required String label,
    required String status,
    required bool isReady,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isReady 
          ? const Color(0xFF059669).withOpacity(0.1)
          : const Color(0xFFD97706).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isReady 
            ? const Color(0xFF059669).withOpacity(0.3)
            : const Color(0xFFD97706).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isReady ? const Color(0xFF059669) : const Color(0xFFD97706),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    color: isReady ? const Color(0xFF059669) : const Color(0xFFD97706),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebActionButton() {
    return BlocBuilder<JobsBloc, JobsState>(
      builder: (context, state) {
        final isLoading = state is JobsLoading;
        final hasVideo = _videoUploadResponse != null || _selectedS3Video != null;
        final hasTranscript = _isTranscriptFromText 
            ? _transcriptController.text.trim().isNotEmpty
            : _transcriptUploadResponse != null;
        final canCreateJob = hasVideo && hasTranscript && _titleController.text.isNotEmpty;
        
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading || !canCreateJob ? null : _createJob,
            style: ElevatedButton.styleFrom(
              backgroundColor: canCreateJob 
                  ? Colors.blue.shade600
                  : Colors.grey.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: canCreateJob ? 4 : 0,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.rocket_launch),
                      const SizedBox(width: 8),
                      Text(
                        canCreateJob 
                            ? 'Generate Short' 
                            : 'Complete Setup',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildVideoPreview() {
    if (_selectedS3Video != null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF2D2D2D) 
              : const Color(0xFFE5E7EB),
          ),
        ),
        child: _selectedS3Video!.thumbnailUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _selectedS3Video!.thumbnailUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.video_file, size: 48),
                    );
                  },
                ),
              )
            : const Center(
                child: Icon(Icons.video_file, size: 48),
              ),
      );
    }
    
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF2D2D2D) 
            : const Color(0xFFE5E7EB),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_call, 
              size: 48, 
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            const Text('Select a video to see preview'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Video Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter video title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Enter video description',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Video Selection',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Video Selection Widget
            VideoSelectionWidget(
              selectedVideo: _selectedS3Video,
              onVideoSelected: (video) {
                setState(() {
                  _selectedS3Video = video;
                  if (video != null) {
                    // Clear uploaded video since we're using S3 video
                    _videoUploadResponse = null;
                    _selectedVideoFile = null;
                    _selectedVideoPlatformFile = null;
                    _showUploadSection = false;
                  }
                });
              },
              onUploadNewVideo: () {
                setState(() {
                  _selectedS3Video = null;
                  _showUploadSection = true;
                });
                _pickVideoFile();
              },
            ),
            // Display selected S3 video details prominently
            if (_selectedS3Video != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    // Video thumbnail/icon
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _selectedS3Video!.thumbnailUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _selectedS3Video!.thumbnailUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(Icons.video_file, size: 30, color: Colors.blue.shade600);
                                },
                              ),
                            )
                          : Icon(Icons.video_file, size: 30, color: Colors.blue.shade600),
                    ),
                    const SizedBox(width: 16),
                    // Video details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
                              const SizedBox(width: 6),
                              const Text(
                                'Selected Video',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedS3Video!.filename,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '${(_selectedS3Video!.fileSize / 1024 / 1024).toStringAsFixed(1)} MB',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (_selectedS3Video!.duration != null) ...[
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.play_circle_outline, size: 12, color: Colors.blue.shade700),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDuration(Duration(seconds: _selectedS3Video!.duration!.toInt())),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Change video button
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedS3Video = null;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade600,
                        side: BorderSide(color: Colors.blue.shade300),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Change', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
            if (_showUploadSection && _selectedS3Video == null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              if (_selectedVideoPlatformFile == null && _videoUploadResponse == null) ...[
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InkWell(
                    onTap: _pickVideoFile,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.video_call,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap to select video file',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Supported formats: MP4, MOV, AVI',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (_selectedVideoPlatformFile != null) ...[
                // For web, show file info; for mobile show video preview
                if (kIsWeb) ...[
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark 
                          ? const Color(0xFF2D2D2D) 
                          : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.video_file,
                          size: 48,
                          color: const Color(0xFF059669),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedVideoPlatformFile!.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(_selectedVideoPlatformFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Duration display for web
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_circle_outline,
                                size: 16,
                                color: Colors.blue.shade600,
                              ),
                              const SizedBox(width: 4),
                              FutureBuilder<String?>(
                                future: _getVideoDurationWeb(_selectedVideoPlatformFile!),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.done) {
                                    return Text(
                                      snapshot.data ?? 'Duration unknown',
                                      style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    );
                                  }
                                  return SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (_selectedVideoFile != null) ...[
                  VideoPreviewWidget(
                    videoFile: _selectedVideoFile!,
                    height: 200,
                    onRemove: _removeVideoFile,
                    showControls: true,
                  ),
                ],
                const SizedBox(height: 8),
                if (!kIsWeb && _selectedVideoFile != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark 
                          ? const Color(0xFF2D2D2D) 
                          : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.video_file, 
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), 
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedVideoFile!.path.split('/').last,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 16),
              BlocBuilder<UploadBloc, UploadState>(
                builder: (context, state) {
                  // Show progress if currently uploading this specific item
                  if (state is UploadProgress && _selectedVideoPlatformFile != null && _videoUploadResponse == null) {
                    return Column(
                      children: [
                        LinearProgressIndicator(value: state.progress),
                        const SizedBox(height: 8),
                        Text(state.message ?? 'Uploading video...'),
                      ],
                    );
                  }
                  
                  // If already uploaded, show success state
                  if (_videoUploadResponse != null) {
                    return Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF059669).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: const Color(0xFF059669)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Video uploaded successfully!',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        _videoUploadResponse!.filename,
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _videoUploadResponse = null;
                              _selectedVideoFile = null;
                              _selectedVideoPlatformFile = null;
                            });
                          },
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Re-upload'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    );
                  }
                  
                  // Show upload button if file selected but not uploaded
                  return ElevatedButton.icon(
                    onPressed: _selectedVideoPlatformFile != null ? _uploadVideo : null,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Upload Video'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transcript',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Text Input'),
                    value: true,
                    groupValue: _isTranscriptFromText,
                    onChanged: (value) {
                      setState(() {
                        _isTranscriptFromText = value!;
                        if (value) {
                          // Clear file upload related data when switching to text input
                          _selectedTranscriptFile = null;
                          _selectedTranscriptPlatformFile = null;
                          _transcriptUploadResponse = null;
                        }
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('File Upload'),
                    value: false,
                    groupValue: _isTranscriptFromText,
                    onChanged: (value) {
                      setState(() {
                        _isTranscriptFromText = false;
                        if (!_isTranscriptFromText) {
                          // Clear text input related data when switching to file upload
                          _transcriptController.clear();
                          _transcriptUploadResponse = null;
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isTranscriptFromText) ...[
              TextFormField(
                controller: _transcriptController,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'Enter your script or transcript here...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a transcript';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // For text input, show immediate green light when text is entered
              _transcriptController.text.trim().isNotEmpty
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade600),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Transcript ready! Your text will be used directly for processing.',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.edit_note, color: Colors.orange.shade600),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Enter your transcript text above to continue.',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ] else ...[
              if (_selectedTranscriptFile == null) ...[
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InkWell(
                    onTap: _pickTranscriptFile,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description,
                          size: 32,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap to select transcript file',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          'Supported formats: TXT, SRT, VTT',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedTranscriptFile!.path.split('/').last,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedTranscriptFile = null;
                          });
                        },
                        icon: const Icon(Icons.close, color: Colors.red),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                BlocBuilder<UploadBloc, UploadState>(
                  builder: (context, state) {
                    // Show progress if currently uploading transcript file
                    if (state is UploadProgress && (_selectedTranscriptPlatformFile != null || _selectedTranscriptFile != null) && _transcriptUploadResponse == null) {
                      return Column(
                        children: [
                          LinearProgressIndicator(value: state.progress),
                          const SizedBox(height: 8),
                          Text(state.message ?? 'Uploading transcript file...'),
                        ],
                      );
                    }
                    
                    // If already uploaded, show success state
                    if (_transcriptUploadResponse != null) {
                      return Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF059669).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: const Color(0xFF059669)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Transcript file uploaded successfully!',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          _transcriptUploadResponse!.filename,
                                          style: const TextStyle(fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _transcriptUploadResponse = null;
                                _selectedTranscriptFile = null;
                                _selectedTranscriptPlatformFile = null;
                              });
                            },
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Re-upload'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      );
                    }
                    
                    // Show upload button if file selected but not uploaded
                    return ElevatedButton.icon(
                      onPressed: (_selectedTranscriptFile != null || _selectedTranscriptPlatformFile != null)
                          ? _uploadTranscriptFile 
                          : null,
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Upload Transcript File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    );
                  },
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      children: [
        // Voice Preview Widget
        VoicePreviewWidget(
          availableVoices: _availableVoices,
          selectedVoice: _selectedVoice,
          onVoiceSelected: (voice) {
            setState(() {
              _selectedVoice = voice;
            });
          },
          transcriptText: _transcriptController.text.isNotEmpty 
              ? _transcriptController.text 
              : null,
        ),
        
        const SizedBox(height: 16),
        
        // Additional Options
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.settings,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Processing Options',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Mock Mode'),
                  subtitle: const Text('Process video for download only (don\'t upload to YouTube)'),
                  value: _mockMode,
                  onChanged: (value) {
                    setState(() {
                      _mockMode = value;
                      if (value) {
                        _autoUploadToYoutube = false; // Disable auto-upload if mock mode is enabled
                      }
                    });
                  },
                ),
                if (!_mockMode) ...[
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Auto-upload to YouTube'),
                    subtitle: const Text('Automatically upload the processed video to YouTube'),
                    value: _autoUploadToYoutube,
                    onChanged: (value) {
                      setState(() {
                        _autoUploadToYoutube = value;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return BlocBuilder<JobsBloc, JobsState>(
      builder: (context, state) {
        final isLoading = state is JobsLoading;
        final hasVideo = _videoUploadResponse != null || _selectedS3Video != null;
        // For text input: green light immediately when text is entered
        // For file upload: green light only after successful upload
        final hasTranscript = _isTranscriptFromText 
            ? _transcriptController.text.trim().isNotEmpty
            : _transcriptUploadResponse != null;
        final canCreateJob = hasVideo && hasTranscript;
        
        return Column(
          children: [
            // Status indicators
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                                          color: hasVideo
                        ? Colors.green.shade50 
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hasVideo
                          ? Colors.green.shade200 
                          : Colors.orange.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasVideo
                            ? Icons.check_circle 
                            : Icons.video_file,
                        color: hasVideo
                            ? Colors.green.shade600 
                            : Colors.orange.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        hasVideo
                            ? 'Video Ready' 
                            : 'Video Required',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: hasVideo
                              ? Colors.green.shade700 
                              : Colors.orange.shade700,
                        ),
                      ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                                          color: hasTranscript
                        ? Colors.green.shade50 
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hasTranscript
                          ? Colors.green.shade200 
                          : Colors.orange.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasTranscript
                            ? Icons.check_circle 
                            : Icons.text_fields,
                        color: hasTranscript
                            ? Colors.green.shade600 
                            : Colors.orange.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        hasTranscript
                            ? 'Transcript Ready' 
                            : 'Transcript Required',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: hasTranscript
                              ? Colors.green.shade700 
                              : Colors.orange.shade700,
                        ),
                      ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetForm,
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading || !canCreateJob ? null : _createJob,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canCreateJob 
                          ? Colors.green.shade600 
                          : Colors.grey.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            canCreateJob 
                                ? 'Create Short' 
                                : 'Upload Required Files',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
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
      
      // Show dialog asking if user wants to upload immediately
      if (mounted && _titleController.text.isNotEmpty) {
        final shouldUpload = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Upload Video Now?'),
            content: const Text('Do you want to upload the selected video immediately?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Later'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Upload Now'),
              ),
            ],
          ),
        );
        
        if (shouldUpload == true) {
          _uploadVideo();
        }
      } else if (_titleController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a title first to enable auto-upload'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _pickTranscriptFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'srt', 'vtt'],
    );
    
    if (result != null && result.files.isNotEmpty) {
      final platformFile = result.files.first;
      setState(() {
        _selectedTranscriptPlatformFile = platformFile;
        // For non-web platforms, still create File object
        if (!kIsWeb && platformFile.path != null) {
          _selectedTranscriptFile = File(platformFile.path!);
        }
      });
      
      // Auto-upload transcript file immediately after selection
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uploading transcript file...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
        _uploadTranscriptFile();
      }
    }
  }

  void _removeVideoFile() {
    setState(() {
      _selectedVideoFile = null;
      _selectedVideoPlatformFile = null;
      _videoUploadResponse = null;
    });
  }

  void _uploadVideo() {
    if (_selectedVideoPlatformFile != null && _titleController.text.isNotEmpty) {
      if (kIsWeb) {
        // For web, we need to pass the bytes
        context.read<UploadBloc>().add(
          UploadVideoEvent(
            videoFile: null,
            title: _titleController.text,
            description: _descriptionController.text.isNotEmpty 
                ? _descriptionController.text 
                : null,
            platformFile: _selectedVideoPlatformFile!,
          ),
        );
      } else if (_selectedVideoFile != null) {
        // For mobile, use the File object
        context.read<UploadBloc>().add(
          UploadVideoEvent(
            videoFile: _selectedVideoFile!,
            title: _titleController.text,
            description: _descriptionController.text.isNotEmpty 
                ? _descriptionController.text 
                : null,
          ),
        );
      }
    }
  }

  void _uploadTranscriptText() {
    if (_transcriptController.text.isNotEmpty) {
      context.read<UploadBloc>().add(
        UploadTranscriptTextEvent(
          transcriptText: _transcriptController.text,
          title: _titleController.text.isNotEmpty 
              ? _titleController.text 
              : 'Transcript',
        ),
      );
    }
  }

  void _uploadTranscriptFile() {
    if (_selectedTranscriptPlatformFile != null) {
      if (kIsWeb) {
        // For web, we need to pass the platform file
        context.read<UploadBloc>().add(
          UploadTranscriptFileEvent(
            transcriptFile: null,
            title: _titleController.text.isNotEmpty 
                ? _titleController.text 
                : 'Transcript File',
            platformFile: _selectedTranscriptPlatformFile!,
          ),
        );
      } else if (_selectedTranscriptFile != null) {
        // For mobile, use the File object
        context.read<UploadBloc>().add(
          UploadTranscriptFileEvent(
            transcriptFile: _selectedTranscriptFile!,
            title: _titleController.text.isNotEmpty 
                ? _titleController.text 
                : 'Transcript File',
          ),
        );
      }
    }
  }

  void _createJob() {
    // Validate form
    if (!_formKey.currentState!.validate()) return;
    
    // Check if transcript is available
    final hasTranscript = _transcriptUploadResponse != null || _transcriptController.text.isNotEmpty;
    if (!hasTranscript) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a transcript or upload a transcript file'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Check if either S3 video is selected or video is uploaded
    if (_selectedS3Video == null && _videoUploadResponse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a video or upload a new one'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Create job request based on video source
    CreateJobRequest request;
    
    // Determine transcript source (prioritize uploaded file over text)
    final String? transcriptUploadId = _transcriptUploadResponse?.uploadId;
    final String? transcriptText = transcriptUploadId == null && _transcriptController.text.isNotEmpty 
        ? _transcriptController.text 
        : null;
    
    if (_selectedS3Video != null) {
      // Using S3 video
      request = CreateJobRequest(
        s3VideoId: _selectedS3Video!.id,
        transcriptUploadId: transcriptUploadId,
        transcriptText: transcriptText,
        title: _titleController.text,
        description: _descriptionController.text.isNotEmpty 
            ? _descriptionController.text 
            : 'YouTube Short created with AI',
        voice: _selectedVoice ?? 'alloy',
        tags: ['ai', 'shorts', 'youtube'],
        mockMode: _mockMode,
      );
    } else {
      // Using uploaded video
      request = CreateJobRequest(
        videoUploadId: _videoUploadResponse!.uploadId,
        transcriptUploadId: transcriptUploadId,
        transcriptText: transcriptText,
        title: _titleController.text,
        description: _descriptionController.text.isNotEmpty 
            ? _descriptionController.text 
            : 'YouTube Short created with AI',
        voice: _selectedVoice ?? 'alloy',
        tags: ['ai', 'shorts', 'youtube'],
        mockMode: _mockMode,
      );
    }
    
    context.read<JobsBloc>().add(CreateJobEvent(request));
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _descriptionController.clear();
    _transcriptController.clear();
    
    setState(() {
      _selectedVideoFile = null;
      _selectedTranscriptFile = null;
      _selectedVideoPlatformFile = null;
      _selectedTranscriptPlatformFile = null;
      _videoUploadResponse = null;
      _transcriptUploadResponse = null;
      _selectedS3Video = null;
      _showUploadSection = false;
      _isTranscriptFromText = true;
      _autoUploadToYoutube = false;
      _mockMode = false;
      _selectedVoice = 'alloy';
    });
    
    context.read<UploadBloc>().add(ResetUploadEvent());
  }

  Future<void> _downloadProcessedVideo(String jobId) async {
    try {
      // Use the API constants for the download URL
      final downloadUrl = '${ApiConstants.apiBaseUrl}${ApiConstants.downloadJobVideo(jobId)}';
      
      if (kIsWeb) {
        // For web platform, trigger download via anchor element
        html.AnchorElement(href: downloadUrl)
          ..setAttribute('download', 'processed_video_$jobId.mp4')
          ..setAttribute('target', '_blank')
          ..click();
      } else {
        // For mobile platforms, open the download URL
        final uri = Uri.parse(downloadUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch download';
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download started successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      print('Download error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _getVideoDurationWeb(PlatformFile videoFile) async {
    try {
      if (kIsWeb && videoFile.bytes != null) {
        // Create a video element to get duration
        final blob = html.Blob([videoFile.bytes!]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        
        final video = html.VideoElement()
          ..src = url
          ..preload = 'metadata';
        
        // Wait for metadata to load
        await video.onLoadedMetadata.first;
        
        final duration = video.duration;
        html.Url.revokeObjectUrl(url);
        
        if (duration != null && !duration.isNaN && duration.isFinite) {
          return _formatDuration(Duration(seconds: duration.toInt()));
        }
      }
      return null;
    } catch (e) {
      print('Error getting video duration: $e');
      return null;
    }
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

  void _showSuccessDialog(JobResponse job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_mockMode ? 'Job Created Successfully!' : 'Job Created Successfully!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Job ID: ${job.jobId}'),
            const SizedBox(height: 8),
            Text('Status: ${job.status}'),
            const SizedBox(height: 8),
            if (_mockMode) ...[
              const Row(
                children: [
                  Icon(Icons.download, color: Colors.blue, size: 16),
                  SizedBox(width: 4),
                  Text('Mock Mode', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Your video will be processed for download only. No YouTube upload will occur.'),
            ] else ...[
              const Row(
                children: [
                  Icon(Icons.upload, color: Colors.red, size: 16),
                  SizedBox(width: 4),
                  Text('YouTube Upload', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Your video is being processed and will be uploaded to YouTube.'),
            ],
            const SizedBox(height: 8),
            const Text('You can track the progress in the Jobs section.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/jobs',
                (route) => route.isFirst,
              );
            },
            child: const Text('View Jobs'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetForm();
            },
            child: const Text('Create Another'),
          ),
        ],
      ),
    );
  }
} 
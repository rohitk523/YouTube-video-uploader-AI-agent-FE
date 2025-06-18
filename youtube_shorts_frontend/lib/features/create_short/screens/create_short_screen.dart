import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../../../shared/models/upload_models.dart';
import '../../../shared/models/job_models.dart';
import '../../../shared/widgets/video_preview_widget.dart';
import '../../upload/bloc/upload_bloc.dart';
import '../../upload/bloc/upload_event.dart';
import '../../upload/bloc/upload_state.dart';
import '../../jobs/bloc/jobs_bloc.dart';
import '../../jobs/bloc/jobs_event.dart';
import '../../jobs/bloc/jobs_state.dart';

class CreateShortScreen extends StatefulWidget {
  const CreateShortScreen({super.key});

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
  
  bool _isTranscriptFromText = true;
  bool _autoUploadToYoutube = false;
  String? _selectedVoice;
  
  final List<String> _availableVoices = [
    'alloy', 'echo', 'fable', 'onyx', 'nova', 'shimmer'
  ];

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
        appBar: AppBar(
          title: const Text('Create YouTube Short'),
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
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
                _videoUploadResponse = state.uploadResponse;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Video uploaded successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (state is TranscriptUploadSuccess) {
                _transcriptUploadResponse = state.uploadResponse;
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildVideoSection(),
                    const SizedBox(height: 24),
                    _buildTranscriptSection(),
                    const SizedBox(height: 24),
                    _buildDetailsSection(),
                    const SizedBox(height: 24),
                    _buildOptionsSection(),
                    const SizedBox(height: 32),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
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
              'Video Upload',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedVideoPlatformFile == null) ...[
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
            ] else ...[
              // For web, show file info; for mobile show video preview
              if (kIsWeb) ...[
                Container(
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.video_file,
                        size: 48,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedVideoPlatformFile!.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(_selectedVideoPlatformFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                        style: TextStyle(
                          color: Colors.grey.shade600,
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
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.video_file, color: Colors.grey.shade600, size: 16),
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
                if (state is UploadProgress && _selectedVideoPlatformFile != null) {
                  return Column(
                    children: [
                      LinearProgressIndicator(value: state.progress),
                      const SizedBox(height: 8),
                      Text(state.message ?? 'Uploading...'),
                    ],
                  );
                }
                return ElevatedButton.icon(
                  onPressed: _selectedVideoPlatformFile != null ? _uploadVideo : null,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Upload Video'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                  ),
                );
              },
            ),
            if (_videoUploadResponse != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Video uploaded: ${_videoUploadResponse!.filename}',
                  style: TextStyle(color: Colors.green.shade700),
                ),
              ),
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
                        if (!value) {
                          _transcriptController.clear();
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
                        _isTranscriptFromText = !value!;
                        if (value!) {
                          _selectedTranscriptFile = null;
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
              BlocBuilder<UploadBloc, UploadState>(
                builder: (context, state) {
                  return ElevatedButton.icon(
                    onPressed: _transcriptController.text.isNotEmpty 
                        ? _uploadTranscriptText 
                        : null,
                    icon: const Icon(Icons.text_fields),
                    label: const Text('Upload Transcript'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                  );
                },
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
                    return ElevatedButton.icon(
                      onPressed: _selectedTranscriptPlatformFile != null 
                          ? _uploadTranscriptFile 
                          : null,
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Upload Transcript File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                      ),
                    );
                  },
                ),
              ],
            ],
            if (_transcriptUploadResponse != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Transcript uploaded: ${_transcriptUploadResponse!.filename}',
                  style: TextStyle(color: Colors.green.shade700),
                ),
              ),
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

  Widget _buildOptionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedVoice,
              decoration: const InputDecoration(
                labelText: 'Voice for TTS',
                border: OutlineInputBorder(),
              ),
              items: _availableVoices.map((voice) {
                return DropdownMenuItem(
                  value: voice,
                  child: Text(voice.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedVoice = value;
                });
              },
            ),
            const SizedBox(height: 16),
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
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return BlocBuilder<JobsBloc, JobsState>(
      builder: (context, state) {
        final isLoading = state is JobsLoading;
        final canCreateJob = _videoUploadResponse != null && 
                            _transcriptUploadResponse != null;
        
        return Row(
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
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Short'),
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
    if (_formKey.currentState!.validate() && 
        _videoUploadResponse != null && 
        _transcriptUploadResponse != null) {
      
      final request = CreateJobRequest(
        videoUploadId: _videoUploadResponse!.uploadId,
        transcriptUploadId: _transcriptUploadResponse!.uploadId,
        outputTitle: _titleController.text,
        outputDescription: _descriptionController.text.isNotEmpty 
            ? _descriptionController.text 
            : null,
        voice: _selectedVoice,
        autoUpload: _autoUploadToYoutube,
      );
      
      context.read<JobsBloc>().add(CreateJobEvent(request));
    }
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
      _isTranscriptFromText = true;
      _autoUploadToYoutube = false;
      _selectedVoice = null;
    });
    
    context.read<UploadBloc>().add(ResetUploadEvent());
  }

  void _showSuccessDialog(JobResponse job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Job Created Successfully!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Job ID: ${job.jobId}'),
            const SizedBox(height: 8),
            Text('Status: ${job.status}'),
            const SizedBox(height: 8),
            const Text('Your video is now being processed. You can track the progress in the Jobs section.'),
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
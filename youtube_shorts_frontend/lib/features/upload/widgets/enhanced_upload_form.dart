import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../shared/models/upload_models.dart';

class EnhancedUploadForm extends StatefulWidget {
  final Function(VideoUploadRequest) onVideoUpload;
  final Function(EnhancedTranscriptUploadRequest) onTranscriptUpload;
  final bool isLoading;

  const EnhancedUploadForm({
    Key? key,
    required this.onVideoUpload,
    required this.onTranscriptUpload,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<EnhancedUploadForm> createState() => _EnhancedUploadFormState();
}

class _EnhancedUploadFormState extends State<EnhancedUploadForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _videoNameController = TextEditingController();
  final _transcriptNameController = TextEditingController();
  final _transcriptContentController = TextEditingController();

  File? _selectedVideoFile;
  String _selectedVideoFileName = '';
  bool _useCustomVideoName = false;
  bool _useCustomTranscriptName = false;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title Field
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title *',
              hintText: 'Enter your video title',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Title is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Description Field
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description *',
              hintText: 'Enter your video description',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Description is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Video Upload Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Video Upload',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  
                  // Video File Picker
                  ElevatedButton.icon(
                    onPressed: widget.isLoading ? null : _pickVideoFile,
                    icon: const Icon(Icons.video_file),
                    label: Text(_selectedVideoFile == null 
                        ? 'Select Video File' 
                        : _selectedVideoFileName),
                  ),
                  
                  if (_selectedVideoFile != null) ...[
                    const SizedBox(height: 12),
                    
                    // Custom Video Name Option
                    CheckboxListTile(
                      title: const Text('Use custom name for video'),
                      subtitle: const Text('Give your video a memorable name'),
                      value: _useCustomVideoName,
                      onChanged: (value) {
                        setState(() {
                          _useCustomVideoName = value ?? false;
                          if (!_useCustomVideoName) {
                            _videoNameController.clear();
                          }
                        });
                      },
                    ),
                    
                    if (_useCustomVideoName) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _videoNameController,
                        decoration: const InputDecoration(
                          labelText: 'Custom Video Name',
                          hintText: 'e.g., my-awesome-video',
                          border: OutlineInputBorder(),
                          helperText: 'This name will help you identify your video',
                        ),
                        validator: _useCustomVideoName ? (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Custom video name is required when enabled';
                          }
                          return null;
                        } : null,
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Transcript Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transcript',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  
                  // Transcript Content
                  TextFormField(
                    controller: _transcriptContentController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Transcript Content *',
                      hintText: 'Enter your transcript text...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Transcript content is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Custom Transcript Name Option
                  CheckboxListTile(
                    title: const Text('Use custom name for transcript'),
                    subtitle: const Text('Give your transcript a memorable name'),
                    value: _useCustomTranscriptName,
                    onChanged: (value) {
                      setState(() {
                        _useCustomTranscriptName = value ?? false;
                        if (!_useCustomTranscriptName) {
                          _transcriptNameController.clear();
                        }
                      });
                    },
                  ),
                  
                  if (_useCustomTranscriptName) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _transcriptNameController,
                      decoration: const InputDecoration(
                        labelText: 'Custom Transcript Name',
                        hintText: 'e.g., my-transcript',
                        border: OutlineInputBorder(),
                        helperText: 'This name will help you identify your transcript',
                      ),
                      validator: _useCustomTranscriptName ? (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Custom transcript name is required when enabled';
                        }
                        return null;
                      } : null,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Upload Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.isLoading || _selectedVideoFile == null 
                      ? null 
                      : _uploadVideo,
                  icon: widget.isLoading 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload),
                  label: Text(widget.isLoading ? 'Uploading...' : 'Upload Video'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.isLoading || 
                      _transcriptContentController.text.trim().isEmpty
                      ? null 
                      : _uploadTranscript,
                  icon: const Icon(Icons.text_snippet),
                  label: const Text('Upload Transcript'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickVideoFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedVideoFile = File(result.files.single.path!);
        _selectedVideoFileName = result.files.single.name;
      });
    }
  }

  void _uploadVideo() {
    if (!_formKey.currentState!.validate()) return;

    final request = VideoUploadRequest(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      customName: _useCustomVideoName && _videoNameController.text.trim().isNotEmpty
          ? _videoNameController.text.trim()
          : null,
      isTemp: true,
    );

    widget.onVideoUpload(request);
  }

  void _uploadTranscript() {
    if (!_formKey.currentState!.validate()) return;

    final request = EnhancedTranscriptUploadRequest(
      content: _transcriptContentController.text.trim(),
      customName: _useCustomTranscriptName && _transcriptNameController.text.trim().isNotEmpty
          ? _transcriptNameController.text.trim()
          : null,
      isTemp: true,
    );

    widget.onTranscriptUpload(request);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _videoNameController.dispose();
    _transcriptNameController.dispose();
    _transcriptContentController.dispose();
    super.dispose();
  }
} 
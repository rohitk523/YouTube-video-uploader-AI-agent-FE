import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/ui_constants.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  bool _videoUploaded = false;
  bool _transcriptUploaded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Content'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: UIConstants.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: UIConstants.largeRadius,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_upload,
                    size: UIConstants.extraLargeIconSize * 2,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Upload Your Content',
                    style: AppTextStyles.headline5,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start by uploading your video and transcript to create amazing YouTube Shorts',
                    style: AppTextStyles.bodyText2,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Video Upload Card
            _buildUploadCard(
              title: 'Video Upload',
              subtitle: 'Upload your video file (MP4, MOV, AVI)',
              icon: Icons.video_file,
              uploaded: _videoUploaded,
              onTap: () => _handleVideoUpload(),
              details: [
                'Supported formats: ${AppConstants.supportedVideoExtensions.join(', ').toUpperCase()}',
                'Maximum size: ${ApiConstants.maxVideoSizeMB}MB',
                'Recommended: 1080p or higher',
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Transcript Upload Card
            _buildUploadCard(
              title: 'Transcript Upload',
              subtitle: 'Add your transcript or script',
              icon: Icons.text_snippet,
              uploaded: _transcriptUploaded,
              onTap: () => _handleTranscriptUpload(),
              details: [
                'Supported formats: ${AppConstants.supportedTranscriptExtensions.join(', ').toUpperCase()}',
                'Maximum length: ${ApiConstants.maxTranscriptLength} characters',
                'You can also type directly in the app',
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Continue Button
            ElevatedButton(
              onPressed: _videoUploaded && _transcriptUploaded ? _handleContinue : null,
              child: const Text('Continue to Create Short'),
            ),
            
            const SizedBox(height: 16),
            
            // Help Text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: UIConstants.mediumRadius,
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.info,
                        size: UIConstants.mediumIconSize,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Getting Started',
                        style: AppTextStyles.subtitle2.copyWith(
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Upload your video content (long-form video recommended)\n'
                    '2. Provide a transcript or script for better results\n'
                    '3. Our AI will create engaging short-form content\n'
                    '4. Review and publish to YouTube',
                    style: AppTextStyles.bodyText2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUploadCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool uploaded,
    required VoidCallback onTap,
    required List<String> details,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: UIConstants.mediumRadius,
        child: Padding(
          padding: UIConstants.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: uploaded ? AppColors.success : AppColors.gray200,
                      borderRadius: UIConstants.mediumRadius,
                    ),
                    child: Icon(
                      uploaded ? Icons.check : icon,
                      color: uploaded ? AppColors.white : AppColors.gray600,
                      size: UIConstants.mediumIconSize,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTextStyles.cardTitle),
                        const SizedBox(height: 4),
                        Text(subtitle, style: AppTextStyles.cardSubtitle),
                      ],
                    ),
                  ),
                  if (uploaded)
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: UIConstants.mediumIconSize,
                    )
                  else
                    Icon(
                      Icons.add_circle_outline,
                      color: AppColors.primary,
                      size: UIConstants.mediumIconSize,
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Details
              ...details.map((detail) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.gray500,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        detail,
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ),
        ),
      ),
    );
  }
  
  void _handleVideoUpload() {
    // TODO: Implement video upload logic
    setState(() {
      _videoUploaded = !_videoUploaded;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_videoUploaded ? 'Video uploaded successfully!' : 'Video upload removed'),
        backgroundColor: _videoUploaded ? AppColors.success : AppColors.warning,
      ),
    );
  }
  
  void _handleTranscriptUpload() {
    // TODO: Implement transcript upload logic
    setState(() {
      _transcriptUploaded = !_transcriptUploaded;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_transcriptUploaded ? 'Transcript uploaded successfully!' : 'Transcript upload removed'),
        backgroundColor: _transcriptUploaded ? AppColors.success : AppColors.warning,
      ),
    );
  }
  
  void _handleContinue() {
    // TODO: Navigate to create short page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigating to Create Short page...'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
} 
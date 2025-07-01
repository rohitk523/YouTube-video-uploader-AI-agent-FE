import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/network/api_client.dart';
import '../../../core/di/service_locator.dart';

class VoicePreviewWidget extends StatefulWidget {
  final List<String> availableVoices;
  final String? selectedVoice;
  final Function(String) onVoiceSelected;
  final String? transcriptText;

  const VoicePreviewWidget({
    super.key,
    required this.availableVoices,
    required this.onVoiceSelected,
    this.selectedVoice,
    this.transcriptText,
  });

  @override
  State<VoicePreviewWidget> createState() => _VoicePreviewWidgetState();
}

class _VoicePreviewWidgetState extends State<VoicePreviewWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ApiClient _apiClient = getIt<ApiClient>();
  
  String? _currentlyPlaying;
  bool _isLoading = false;
  Map<String, String> _voiceDescriptions = {};
  Map<String, bool> _voiceLoadingStates = {};

  // Voice information with descriptions and styles
  final Map<String, Map<String, dynamic>> _voiceInfo = {
    'alloy': {
      'name': 'Alloy',
      'description': 'Balanced and clear, good for most content',
      'style': 'Neutral',
      'icon': Icons.record_voice_over,
      'color': Colors.blue,
    },
    'echo': {
      'name': 'Echo',
      'description': 'Energetic and dynamic, great for engaging content',
      'style': 'Energetic',
      'icon': Icons.campaign,
      'color': Colors.orange,
    },
    'fable': {
      'name': 'Fable',
      'description': 'Warm and storytelling, perfect for narratives',
      'style': 'Warm',
      'icon': Icons.menu_book,
      'color': Colors.green,
    },
    'onyx': {
      'name': 'Onyx',
      'description': 'Deep and authoritative, ideal for serious content',
      'style': 'Authoritative',
      'icon': Icons.business,
      'color': Colors.grey,
    },
    'nova': {
      'name': 'Nova',
      'description': 'Bright and engaging, excellent for upbeat content',
      'style': 'Bright',
      'icon': Icons.star,
      'color': Colors.purple,
    },
    'shimmer': {
      'name': 'Shimmer',
      'description': 'Soft and gentle, soothing for calm content',
      'style': 'Gentle',
      'icon': Icons.auto_awesome,
      'color': Colors.pink,
    },
  };

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed) {
        setState(() {
          _currentlyPlaying = null;
        });
      }
    });
  }

  Future<void> _playVoicePreview(String voice) async {
    try {
      // Stop any currently playing audio
      if (_currentlyPlaying != null) {
        await _audioPlayer.stop();
      }

      setState(() {
        _voiceLoadingStates[voice] = true;
      });

      // Use custom text if available, otherwise use default
      String? previewText = widget.transcriptText?.isNotEmpty == true 
          ? widget.transcriptText!.substring(0, widget.transcriptText!.length > 100 ? 100 : widget.transcriptText!.length)
          : null;

      // Get audio URL from backend
      String audioUrl = await _apiClient.getVoicePreviewDownloadUrl(
        voice: voice,
        customText: previewText,
      );

      // Play the audio
      await _audioPlayer.play(UrlSource(audioUrl));

      setState(() {
        _currentlyPlaying = voice;
        _voiceLoadingStates[voice] = false;
      });

    } catch (e) {
      setState(() {
        _voiceLoadingStates[voice] = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play voice preview: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopVoicePreview() async {
    await _audioPlayer.stop();
    setState(() {
      _currentlyPlaying = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.voice_over_off,
                  color: Colors.blue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Choose Your Voice',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                if (widget.transcriptText?.isNotEmpty == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.text_fields, size: 14, color: Colors.green[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Using your text',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Tap any voice to hear a preview with your content',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            
            // Voice Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: widget.availableVoices.length,
              itemBuilder: (context, index) {
                final voice = widget.availableVoices[index];
                return _buildVoiceCard(voice);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceCard(String voice) {
    final voiceInfo = _voiceInfo[voice] ?? {
      'name': voice.toUpperCase(),
      'description': 'AI generated voice',
      'style': 'Standard',
      'icon': Icons.record_voice_over,
      'color': Colors.grey,
    };

    final isSelected = widget.selectedVoice == voice;
    final isPlaying = _currentlyPlaying == voice;
    final isLoading = _voiceLoadingStates[voice] ?? false;

    return GestureDetector(
      onTap: () {
        widget.onVoiceSelected(voice);
        if (isPlaying) {
          _stopVoicePreview();
        } else {
          _playVoicePreview(voice);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isSelected ? voiceInfo['color'].withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? voiceInfo['color'] : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: voiceInfo['color'].withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Voice Icon and Play Button
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: voiceInfo['color'].withOpacity(0.2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(
                      voiceInfo['icon'],
                      color: voiceInfo['color'],
                      size: 24,
                    ),
                  ),
                  if (isLoading)
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    )
                  else if (isPlaying)
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Icon(
                        Icons.stop,
                        color: Colors.white,
                        size: 20,
                      ),
                    )
                  else
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Voice Name
              Text(
                voiceInfo['name'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? voiceInfo['color'] : Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 4),
              
              // Voice Style
              Text(
                voiceInfo['style'],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? voiceInfo['color'] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              // Voice Description
              Text(
                voiceInfo['description'],
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
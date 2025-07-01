import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/config/environment.dart';
import '../../../core/constants/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart' as dio;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

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
  final ApiClient _apiClient = getIt<ApiClient>();
  
  String? _currentlyPlaying;
  bool _isLoading = false;
  Map<String, String> _voiceDescriptions = {};
  Map<String, bool> _voiceLoadingStates = {};
  
  // HTML5 audio element for web playback
  html.AudioElement? _currentAudioElement;
  
  // Client-side caching for audio blobs
  static final Map<String, String> _audioBlobCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  
  // Cache duration (15 minutes to match backend expiry)
  static const Duration _cacheDuration = Duration(minutes: 15);

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
  }

  // Get access token for authenticated requests
  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConstants.accessTokenKey);
  }

  // Cache management methods
  String? _getCachedAudioBlob(String cacheKey) {
    _cleanupExpiredCache();
    
    if (_audioBlobCache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null && DateTime.now().difference(timestamp) < _cacheDuration) {
        return _audioBlobCache[cacheKey];
      } else {
        // Remove expired entry
        final blobUrl = _audioBlobCache.remove(cacheKey);
        if (blobUrl != null) {
          html.Url.revokeObjectUrl(blobUrl);
        }
        _cacheTimestamps.remove(cacheKey);
      }
    }
    return null;
  }

  void _cacheAudioBlob(String cacheKey, String blobUrl) {
    _audioBlobCache[cacheKey] = blobUrl;
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  void _cleanupExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp) >= _cacheDuration) {
        expiredKeys.add(key);
      }
    });
    
    for (final key in expiredKeys) {
      final blobUrl = _audioBlobCache.remove(key);
      if (blobUrl != null) {
        html.Url.revokeObjectUrl(blobUrl);
      }
      _cacheTimestamps.remove(key);
    }
  }

  void _playAudioFromBlob(String voice, String blobUrl) {
    // Create HTML5 audio element with blob URL
    _currentAudioElement = html.AudioElement(blobUrl);
    _currentAudioElement!.preload = 'auto';
    
    // Setup event listeners
    _currentAudioElement!.onLoadedData.listen((_) {
      if (mounted) {
        setState(() {
          _voiceLoadingStates[voice] = false;
          _currentlyPlaying = voice;
        });
        // Start playback
        _currentAudioElement!.play();
      }
    });

    _currentAudioElement!.onEnded.listen((_) {
      if (mounted) {
        setState(() {
          _currentlyPlaying = null;
        });
      }
    });

    _currentAudioElement!.onError.listen((error) {
      if (mounted) {
        setState(() {
          _voiceLoadingStates[voice] = false;
          _currentlyPlaying = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play ${voice.toUpperCase()} preview'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    // Load the audio
    _currentAudioElement!.load();
  }

  @override
  void dispose() {
    _stopVoicePreview();
    // Clean up cache when widget is disposed
    _cleanupExpiredCache();
    super.dispose();
  }

  Future<void> _playVoicePreview(String voice) async {
    try {
      // Stop any currently playing audio
      if (_currentlyPlaying != null) {
        _stopVoicePreview();
      }

      // Prevent multiple simultaneous calls for the same voice
      if (_voiceLoadingStates[voice] == true) {
        return;
      }

      setState(() {
        _voiceLoadingStates[voice] = true;
      });

      // Generate cache key based on voice and transcript
      String? previewText = widget.transcriptText?.isNotEmpty == true 
          ? widget.transcriptText!.substring(0, widget.transcriptText!.length > 100 ? 100 : widget.transcriptText!.length)
          : null;
      
      String cacheKey = '$voice${previewText != null ? '_${previewText.hashCode}' : ''}';
      
      // Check if we have a valid cached audio blob
      String? cachedBlobUrl = _getCachedAudioBlob(cacheKey);
      if (cachedBlobUrl != null) {
        _playAudioFromBlob(voice, cachedBlobUrl);
        return;
      }

      if (kIsWeb) {
        // First try to download from backend cache (skip generation if already cached)
        try {
          // Try downloading directly first - this will work if backend has it cached
          final response = await _apiClient.get<List<int>>(
            '/youtube/voices/preview/$voice/download',
            options: dio.Options(
              responseType: dio.ResponseType.bytes,
              headers: {'Accept': 'audio/*'},
            ),
          );
          
          if (response.data != null) {
            // Successfully downloaded from backend cache
            final blob = html.Blob([response.data], 'audio/mpeg');
            final blobUrl = html.Url.createObjectUrlFromBlob(blob);
            
            // Cache the blob URL locally
            _cacheAudioBlob(cacheKey, blobUrl);
            
            // Play the audio
            _playAudioFromBlob(voice, blobUrl);
            return;
          }
        } catch (downloadError) {
          // Backend cache miss - need to generate preview first
          try {
            // Generate voice preview with custom text if available
            await _apiClient.generateVoicePreview(
              voice: voice,
              customText: previewText,
            );

            // Now download the generated audio
            final response = await _apiClient.get<List<int>>(
              '/youtube/voices/preview/$voice/download',
              options: dio.Options(
                responseType: dio.ResponseType.bytes,
                headers: {'Accept': 'audio/*'},
              ),
            );
            
            if (response.data != null) {
              // Create blob from bytes and generate blob URL
              final blob = html.Blob([response.data], 'audio/mpeg');
              final blobUrl = html.Url.createObjectUrlFromBlob(blob);
              
              // Cache the blob URL
              _cacheAudioBlob(cacheKey, blobUrl);
              
              // Play the audio
              _playAudioFromBlob(voice, blobUrl);
              
            } else {
              throw Exception('No audio data received after generation');
            }
          } catch (generateError) {
            setState(() {
              _voiceLoadingStates[voice] = false;
              _currentlyPlaying = null;
            });
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to generate ${voice.toUpperCase()} preview'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
        
      } else {
        // For mobile platforms, we'll implement this later
        setState(() {
          _voiceLoadingStates[voice] = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Voice preview available on web version'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

    } catch (e) {
      setState(() {
        _voiceLoadingStates[voice] = false;
        _currentlyPlaying = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load voice preview'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _stopVoicePreview() {
    if (_currentAudioElement != null) {
      try {
        _currentAudioElement!.pause();
        _currentAudioElement!.currentTime = 0; // Reset to beginning
      } catch (e) {
        // Ignore errors on cleanup
      }
      _currentAudioElement = null;
    }
    
    if (mounted) {
      setState(() {
        _currentlyPlaying = null;
      });
    }
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
            
            // Voice List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.availableVoices.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final voice = widget.availableVoices[index];
                return _buildVoiceListItem(voice);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceListItem(String voice) {
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
          child: Row(
            children: [
              // Voice Icon
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
              
              const SizedBox(width: 16),
              
              // Voice Information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          voiceInfo['name'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? voiceInfo['color'] : Colors.grey[800],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: voiceInfo['color'].withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            voiceInfo['style'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: voiceInfo['color'],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 6),
                    
                    Text(
                      voiceInfo['description'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Play Button
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isSelected ? voiceInfo['color'] : Colors.grey[400],
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: (isSelected ? voiceInfo['color'] : Colors.grey[400]!).withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 24,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }


} 
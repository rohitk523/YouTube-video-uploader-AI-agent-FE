import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/app_router.dart';
import '../../../shared/models/secret_models.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import '../repository/secret_repository.dart';
import '../../../core/di/service_locator.dart';
import 'package:flutter/foundation.dart';

class SecretUploadScreen extends StatefulWidget {
  const SecretUploadScreen({super.key});

  @override
  State<SecretUploadScreen> createState() => _SecretUploadScreenState();
}

class _SecretUploadScreenState extends State<SecretUploadScreen> {
  File? _selectedFile;
  PlatformFile? _selectedPlatformFile;
  bool _isUploading = false;
  bool _isValidating = false;
  bool _isCheckingAuth = false;
  bool _isAuthenticating = false;
  bool _isCheckingStatus = false; // Prevent multiple simultaneous status checks
  SecretValidationResponse? _validationResult;
  SecretStatusResponse? _secretStatus;
  YouTubeAuthStatusResponse? _youtubeAuthStatus;
  final SecretRepository _secretRepository = getIt<SecretRepository>();
  
  int _currentStep = 1; // 1 = Upload secrets, 2 = YouTube OAuth, 3 = Complete
  
  // Add debounce timer to prevent rapid API calls
  Timer? _debounceTimer;
  Timer? _pollingTimer; // Timer for auth polling

  @override
  void initState() {
    super.initState();
    _checkCurrentStatus();
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    _pollingTimer?.cancel();
    _isAuthenticating = false; // Stop polling
    super.dispose();
  }

  Future<void> _checkCurrentStatus() async {
    // Prevent multiple simultaneous calls
    if (_isCheckingStatus) return;
    
    // Cancel any existing timer
    _debounceTimer?.cancel();
    
    // Debounce the call to prevent rapid successive calls
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (_isCheckingStatus) return;
      
      _isCheckingStatus = true;
      
      try {
        final status = await _secretRepository.getSecretStatus();
        final authStatus = await _secretRepository.getYouTubeAuthStatus();
        
        if (mounted) {
          setState(() {
            _secretStatus = status;
            _youtubeAuthStatus = authStatus;
            
            if (status.hasSecrets && status.activeSecrets > 0) {
              if (authStatus.isAuthenticated) {
                _currentStep = 3; // Complete
              } else {
                _currentStep = 2; // Need YouTube OAuth
              }
            } else {
              _currentStep = 1; // Need to upload secrets
            }
          });
        }
      } catch (e) {
        // If there's an error, start from step 1
        if (mounted) {
          setState(() {
            _currentStep = 1;
          });
        }
      } finally {
        _isCheckingStatus = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 768 && screenWidth <= 1024;

    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            Navigator.of(context).pushReplacementNamed(AppRouter.login);
          }
        },
        child: Container(
          height: screenHeight,
          child: isDesktop || isTablet 
              ? _buildDesktopLayout()
              : _buildMobileLayout(),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Stack(
      children: [
        // Background layout
        Row(
          children: [
            // Left Panel - Branding
            Expanded(
              flex: 1,
              child: _buildLeftPanel(),
            ),
            // Right Panel - Background
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.grey[50]!,
                      Colors.white,
                      Colors.grey[50]!,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        // Semi-transparent overlay
        Container(
          color: Colors.black.withOpacity(0.1),
        ),
        // Centered Upload Form
        Center(
          child: Container(
            width: 500,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Card(
              elevation: 20,
              shadowColor: Colors.black.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.grey[50]!,
                    ],
                  ),
                ),
                child: SingleChildScrollView(
                  child: _buildUploadForm(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.2,
            child: _buildLeftPanel(),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            child: _buildUploadForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1e3c72), // Dark blue
            Color(0xFF2a5298), // Medium blue
            Color(0xFF3b82f6), // Lighter blue
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.security,
                size: 50,
                color: Color(0xFF3b82f6),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'YouTube OAuth\nSetup',
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width > 768 ? 36 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Upload your Google Cloud Console OAuth credentials to start creating YouTube Shorts.',
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width > 768 ? 18 : 14,
                color: Colors.white.withOpacity(0.9),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadForm() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress indicator
          Row(
            children: [
              _buildStepIndicator(1, _currentStep == 1, 'Upload Secrets'),
              Expanded(child: _buildStepConnector(1, _currentStep > 1)),
              _buildStepIndicator(2, _currentStep == 2, 'YouTube Auth'),
              Expanded(child: _buildStepConnector(2, _currentStep > 2)),
              _buildStepIndicator(3, _currentStep == 3, 'Complete'),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Title
          Text(
            _getStepTitle(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          Text(
            _getStepDescription(),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // Step content
          _buildStepContent(),
          
          const SizedBox(height: 32),
          
          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, bool isActive, String label) {
    final isCompleted = step < _currentStep;
    final isCurrent = step == _currentStep;
    
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted 
                ? const Color(0xFF3b82f6) 
                : isCurrent 
                    ? const Color(0xFF3b82f6)
                    : Colors.grey[300],
            border: Border.all(
              color: isCompleted || isCurrent 
                  ? const Color(0xFF3b82f6) 
                  : Colors.grey[400]!,
              width: 2,
            ),
          ),
          child: Icon(
            isCompleted ? Icons.check : Icons.circle,
            size: isCompleted ? 24 : 12,
            color: isCompleted 
                ? Colors.white 
                : isCurrent 
                    ? Colors.white
                    : Colors.grey[400],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
            color: isCompleted || isCurrent 
                ? const Color(0xFF3b82f6) 
                : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(int step, bool isCompleted) {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: isCompleted ? const Color(0xFF3b82f6) : Colors.grey[300],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildFileUploadArea();
      case 2:
        return _buildOAuthSetup();
      case 3:
        return _buildComplete();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFileUploadArea() {
    return Column(
      children: [
        // Instructions card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    'How to get OAuth credentials:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '1. Go to Google Cloud Console\n'
                '2. Create or select a project\n'
                '3. Enable YouTube Data API v3\n'
                '4. Create OAuth 2.0 credentials\n'
                '5. Download the JSON file',
                style: TextStyle(
                  color: Colors.blue[600],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        // File upload area
        GestureDetector(
          onTap: _isUploading ? null : _pickFile,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedFile != null || _selectedPlatformFile != null ? const Color(0xFF3b82f6) : Colors.grey[300]!,
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
              color: _selectedFile != null || _selectedPlatformFile != null ? Colors.blue[50] : Colors.grey[50],
            ),
            child: Column(
              children: [
                Icon(
                  _selectedFile != null || _selectedPlatformFile != null ? Icons.check_circle : Icons.cloud_upload,
                  size: 64,
                  color: _selectedFile != null || _selectedPlatformFile != null ? const Color(0xFF3b82f6) : Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _selectedFile != null 
                      ? _selectedFile!.path.split('/').last
                      : _selectedPlatformFile != null
                          ? _selectedPlatformFile!.name
                          : 'Click to upload JSON file',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _selectedFile != null || _selectedPlatformFile != null ? const Color(0xFF3b82f6) : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedFile != null || _selectedPlatformFile != null
                      ? 'File selected successfully'
                      : 'Select client_secret.json from Google Cloud Console',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Validation result
        if (_validationResult != null) _buildValidationResult(),
      ],
    );
  }

  Widget _buildValidationResult() {
    if (_validationResult == null) return const SizedBox.shrink();
    
    final isValid = _validationResult!.valid;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isValid ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isValid ? Colors.green[200]! : Colors.red[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isValid ? Icons.check_circle : Icons.error,
                color: isValid ? Colors.green[700] : Colors.red[700],
              ),
              const SizedBox(width: 8),
              Text(
                isValid ? 'File is valid!' : 'File is invalid',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isValid ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ],
          ),
          if (_validationResult!.projectId != null) ...[
            const SizedBox(height: 8),
            Text(
              'Project ID: ${_validationResult!.projectId}',
              style: TextStyle(
                color: Colors.grey[700],
              ),
            ),
          ],
          if (_validationResult!.clientIdPreview != null) ...[
            const SizedBox(height: 4),
            Text(
              'Client ID: ${_validationResult!.clientIdPreview}',
              style: TextStyle(
                color: Colors.grey[700],
              ),
            ),
          ],
          if (_validationResult!.errors.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...(_validationResult!.errors.map((error) => Text(
              '• $error',
              style: TextStyle(color: Colors.red[700]),
            ))),
          ],
        ],
      ),
    );
  }

  Widget _buildOAuthSetup() {
    return Column(
      children: [
        // Instructions card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    'YouTube Authentication Required',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'To upload videos to YouTube, you need to authenticate with your YouTube channel. Click the button below to open the authentication page.',
                style: TextStyle(
                  color: Colors.blue[600],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Auth status
        if (_youtubeAuthStatus != null) _buildAuthStatus(),
        
        const SizedBox(height: 24),
        
        // Auth button
        _buildAuthButton(),
      ],
    );
  }

  Widget _buildComplete() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            children: [
              Icon(
                Icons.check_circle,
                size: 64,
                color: Colors.green[600],
              ),
              const SizedBox(height: 16),
              Text(
                'Setup Complete!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your YouTube OAuth is now configured and ready to use.',
                style: TextStyle(
                  color: Colors.green[600],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              if (_youtubeAuthStatus?.channelTitle != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Connected to: ${_youtubeAuthStatus!.channelTitle}',
                  style: TextStyle(
                    color: Colors.green[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushReplacementNamed(AppRouter.home);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3b82f6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Continue to App',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthStatus() {
    if (_youtubeAuthStatus == null) return const SizedBox.shrink();
    
    final isAuthenticated = _youtubeAuthStatus!.isAuthenticated;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAuthenticated ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAuthenticated ? Colors.green[200]! : Colors.orange[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isAuthenticated ? Icons.check_circle : Icons.warning,
            color: isAuthenticated ? Colors.green[700] : Colors.orange[700],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAuthenticated ? 'Authenticated' : 'Not Authenticated',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isAuthenticated ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
                if (isAuthenticated && _youtubeAuthStatus!.channelTitle != null)
                  Text(
                    'Channel: ${_youtubeAuthStatus!.channelTitle}',
                    style: TextStyle(
                      color: Colors.green[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isAuthenticating ? null : _authenticateWithYouTube,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: _isAuthenticating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.play_arrow),
        label: Text(
          _isAuthenticating ? 'Authenticating...' : 'Authenticate with YouTube',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _authenticateWithYouTube() async {
    if (mounted) {
      setState(() {
        _isAuthenticating = true;
      });
    }

    try {
      // Get the auth URL from the backend
      final authResponse = await _secretRepository.getYouTubeAuthUrl();
      
      // Launch the auth URL in the browser
      final uri = Uri.parse(authResponse.authUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        // Start polling for auth completion
        _pollForAuthCompletion();
      } else {
        throw Exception('Could not launch authentication URL');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
      
      Fluttertoast.showToast(
        msg: 'Authentication failed: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _pollForAuthCompletion() async {
    // Cancel any existing polling
    _pollingTimer?.cancel();
    
    int attempts = 0;
    const maxAttempts = 24; // 2 minutes (24 * 5 seconds)
    
    void pollAuthStatus() async {
      if (!_isAuthenticating || !mounted) {
        _pollingTimer?.cancel();
        return;
      }
      
      attempts++;
      
      try {
        final authStatus = await _secretRepository.getYouTubeAuthStatus();
        if (authStatus.isAuthenticated && mounted) {
          _pollingTimer?.cancel();
          setState(() {
            _youtubeAuthStatus = authStatus;
            _isAuthenticating = false;
            _currentStep = 3;
          });
          
          Fluttertoast.showToast(
            msg: 'YouTube authentication successful!',
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );
          
          return;
        }
      } catch (e) {
        print('Auth polling error: $e');
      }
      
      // Continue polling if we haven't reached max attempts
      if (attempts < maxAttempts && _isAuthenticating && mounted) {
        _pollingTimer = Timer(const Duration(seconds: 5), pollAuthStatus);
      } else {
        // Timeout
        if (mounted) {
          setState(() {
            _isAuthenticating = false;
          });
          
          Fluttertoast.showToast(
            msg: 'Authentication timeout. Please try again.',
            backgroundColor: Colors.orange,
            textColor: Colors.white,
          );
        }
      }
    }
    
    // Start polling
    _pollingTimer = Timer(const Duration(seconds: 5), pollAuthStatus);
  }

  Widget _buildActionButtons() {
    switch (_currentStep) {
      case 1:
        return Row(
          children: [
            _buildBackButton(),
            const SizedBox(width: 16),
            _buildUploadButton(),
          ],
        );
      case 2:
        return Row(
          children: [
            _buildBackButton(),
            const SizedBox(width: 16),
            _buildSkipButton(),
          ],
        );
      case 3:
        return const SizedBox.shrink(); // Complete step has its own button
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBackButton() {
    return Expanded(
      child: OutlinedButton(
        onPressed: _isUploading ? null : () {
          Navigator.of(context).pop();
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text('Back'),
      ),
    );
  }

  Widget _buildUploadButton() {
    return Expanded(
      flex: 2,
      child: ElevatedButton(
        onPressed: (((kIsWeb && _selectedPlatformFile != null) || (!kIsWeb && _selectedFile != null)) && 
                    _validationResult?.valid == true && 
                    !_isUploading)
            ? _uploadSecret 
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3b82f6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Upload & Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return Expanded(
      flex: 2,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).pushReplacementNamed(AppRouter.home);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Skip for Now',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        if (kIsWeb) {
          setState(() {
            _selectedPlatformFile = result.files.single;
            _selectedFile = null;
            _validationResult = null;
          });
          await _validateFileWeb(_selectedPlatformFile!);
        } else if (result.files.single.path != null) {
          final file = File(result.files.single.path!);
          setState(() {
            _selectedFile = file;
            _selectedPlatformFile = null;
            _validationResult = null;
          });
          await _validateFile(file);
        }
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error picking file: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _validateFileWeb(PlatformFile platformFile) async {
    if (mounted) {
      setState(() {
        _isValidating = true;
      });
    }
    try {
      final validationResponse = await _secretRepository.validateSecretWeb(platformFile);
      if (mounted) {
        setState(() {
          _validationResult = validationResponse;
          _isValidating = false;
        });
      }
      if (validationResponse.valid) {
        Fluttertoast.showToast(
          msg: 'File validated successfully!',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } else {
        Fluttertoast.showToast(
          msg: 'File validation failed',
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isValidating = false;
          _validationResult = SecretValidationResponse(
            valid: false,
            errors: ['Validation failed: $e'],
          );
        });
      }
      Fluttertoast.showToast(
        msg: 'Validation error: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _validateFile(File file) async {
    if (mounted) {
      setState(() {
        _isValidating = true;
      });
    }

    try {
      final validationResponse = await _secretRepository.validateSecret(file);
      if (mounted) {
        setState(() {
          _validationResult = validationResponse;
          _isValidating = false;
        });
      }

      if (validationResponse.valid) {
        Fluttertoast.showToast(
          msg: 'File validated successfully!',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } else {
        Fluttertoast.showToast(
          msg: 'File validation failed',
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isValidating = false;
          _validationResult = SecretValidationResponse(
            valid: false,
            errors: ['Validation failed: $e'],
          );
        });
      }
      
      Fluttertoast.showToast(
        msg: 'Validation error: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _uploadSecret() async {
    final isWeb = kIsWeb;
    final valid = _validationResult?.valid == true;
    if ((!isWeb && _selectedFile == null) || (isWeb && _selectedPlatformFile == null) || !valid) return;
    if (mounted) {
      setState(() {
        _isUploading = true;
      });
    }
    try {
      final uploadResponse = isWeb
        ? await _secretRepository.uploadSecretWeb(_selectedPlatformFile!)
        : await _secretRepository.uploadSecret(_selectedFile!);
      
      if (mounted) {
        setState(() {
          _isUploading = false;
          _currentStep = 2; // Move to YouTube OAuth step
        });
      }
      
      Fluttertoast.showToast(
        msg: uploadResponse.message,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      
      // Check YouTube auth status for step 2
      _checkCurrentStatus();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
      Fluttertoast.showToast(
        msg: 'Upload failed: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 1:
        return 'Upload OAuth Credentials';
      case 2:
        return 'YouTube OAuth Setup';
      case 3:
        return 'Setup Complete';
      default:
        return '';
    }
  }

  String _getStepDescription() {
    switch (_currentStep) {
      case 1:
        return 'Upload the client_secret.json file from Google Cloud Console';
      case 2:
        return 'Authenticate with YouTube';
      case 3:
        return 'YouTube OAuth setup successful';
      default:
        return '';
    }
  }
} 
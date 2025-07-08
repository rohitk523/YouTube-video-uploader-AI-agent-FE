import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
  SecretValidationResponse? _validationResult;
  final SecretRepository _secretRepository = getIt<SecretRepository>();

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
              _buildStepIndicator(1, true, 'Register'),
              Expanded(child: _buildStepConnector(true)),
              _buildStepIndicator(2, true, 'OAuth Setup'),
              Expanded(child: _buildStepConnector(false)),
              _buildStepIndicator(3, false, 'Complete'),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Title
          Text(
            'Upload OAuth Credentials',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Upload the client_secret.json file from Google Cloud Console',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
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
          _buildFileUploadArea(),
          
          const SizedBox(height: 24),
          
          // Validation result
          if (_validationResult != null) _buildValidationResult(),
          
          const SizedBox(height: 32),
          
          // Action buttons
          Row(
            children: [
              Expanded(
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
              ),
              const SizedBox(width: 16),
              Expanded(
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
                          'Complete Setup',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, bool isCompleted, String label) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted ? const Color(0xFF3b82f6) : Colors.grey[300],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 18,
                  )
                : Text(
                    step.toString(),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isCompleted ? const Color(0xFF3b82f6) : Colors.grey[600],
            fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isCompleted) {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: isCompleted ? const Color(0xFF3b82f6) : Colors.grey[300],
    );
  }

  Widget _buildFileUploadArea() {
    return GestureDetector(
      onTap: _isUploading ? null : _pickFile,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          border: Border.all(
            color: _selectedFile != null ? const Color(0xFF3b82f6) : Colors.grey[300]!,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
          color: _selectedFile != null ? Colors.blue[50] : Colors.grey[50],
        ),
        child: Column(
          children: [
            Icon(
              _selectedFile != null ? Icons.check_circle : Icons.cloud_upload,
              size: 64,
              color: _selectedFile != null ? const Color(0xFF3b82f6) : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFile != null 
                  ? _selectedFile!.path.split('/').last
                  : 'Click to upload JSON file',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _selectedFile != null ? const Color(0xFF3b82f6) : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFile != null 
                  ? 'File selected successfully'
                  : 'Select client_secret.json from Google Cloud Console',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (_isValidating) ...[
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                'Validating file...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
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
    setState(() {
      _isValidating = true;
    });
    try {
      final validationResponse = await _secretRepository.validateSecretWeb(platformFile);
      setState(() {
        _validationResult = validationResponse;
        _isValidating = false;
      });
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
      setState(() {
        _isValidating = false;
        _validationResult = SecretValidationResponse(
          valid: false,
          errors: ['Validation failed: $e'],
        );
      });
      Fluttertoast.showToast(
        msg: 'Validation error: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _validateFile(File file) async {
    setState(() {
      _isValidating = true;
    });

    try {
      final validationResponse = await _secretRepository.validateSecret(file);
      setState(() {
        _validationResult = validationResponse;
        _isValidating = false;
      });

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
      setState(() {
        _isValidating = false;
        _validationResult = SecretValidationResponse(
          valid: false,
          errors: ['Validation failed: $e'],
        );
      });
      
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
    setState(() {
      _isUploading = true;
    });
    try {
      final uploadResponse = isWeb
        ? await _secretRepository.uploadSecretWeb(_selectedPlatformFile!)
        : await _secretRepository.uploadSecret(_selectedFile!);
      Fluttertoast.showToast(
        msg: uploadResponse.message,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      Navigator.of(context).pushReplacementNamed(AppRouter.home);
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      Fluttertoast.showToast(
        msg: 'Upload failed: $e',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }
} 
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../core/utils/app_router.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import '../repository/secret_repository.dart';
import '../../../core/di/service_locator.dart';

class SecretGuardWrapper extends StatefulWidget {
  final Widget child;
  
  const SecretGuardWrapper({
    super.key,
    required this.child,
  });

  @override
  State<SecretGuardWrapper> createState() => _SecretGuardWrapperState();
}

class _SecretGuardWrapperState extends State<SecretGuardWrapper> {
  final SecretRepository _secretRepository = getIt<SecretRepository>();
  bool _isChecking = true;
  bool _hasSecrets = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkSecretStatus();
  }

  Future<void> _checkSecretStatus() async {
    try {
      final status = await _secretRepository.getSecretStatus();
      if (mounted) {
        setState(() {
          _hasSecrets = status.hasSecrets && status.activeSecrets > 0 && status.hasYouTubeAuth;
          _isChecking = false;
        });
      }
      
      if (!_hasSecrets) {
        // Redirect to secret upload screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed(AppRouter.secretUpload);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _errorMessage = 'Failed to check OAuth credentials: $e';
        });
      }
      
      Fluttertoast.showToast(
        msg: 'Please complete OAuth setup to continue',
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      
      // Redirect to secret upload screen on error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppRouter.secretUpload);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushReplacementNamed(AppRouter.login);
        }
      },
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isChecking) {
      return _buildLoadingScreen();
    }
    
    if (_errorMessage != null) {
      return _buildErrorScreen();
    }
    
    if (!_hasSecrets) {
      // This should not be reached as we redirect, but just in case
      return _buildNoSecretsScreen();
    }
    
    // User has secrets, show the protected content
    return widget.child;
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
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
                  size: 80,
                  color: Color(0xFF3b82f6),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Loading text
              Text(
                'Checking OAuth\nCredentials...',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
              
              const SizedBox(height: 16),
              
              // Loading description
              Text(
                'Verifying your YouTube API access...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.error,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Error title
                Text(
                  'Setup Required',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Error message
                Text(
                  _errorMessage ?? 'OAuth credentials are required',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Retry button
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed(AppRouter.secretUpload);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).colorScheme.error,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Upload OAuth Credentials',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoSecretsScreen() {
    return Scaffold(
      backgroundColor: Colors.orange[600],
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Warning icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.warning_amber,
                    size: 80,
                    color: Colors.orange,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Warning title
                Text(
                  'Setup Incomplete',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Warning message
                Text(
                  'You need to upload OAuth credentials to access YouTube features.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Setup button
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed(AppRouter.secretUpload);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.orange[600],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Complete Setup',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 
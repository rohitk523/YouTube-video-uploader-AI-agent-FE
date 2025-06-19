import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_state.dart';
import '../utils/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    // Add a small delay for better UX, then navigate directly to login
    // This bypasses the auth check that might be hanging
    Future.delayed(const Duration(seconds: 2), () {
      print('SplashScreen: Navigating directly to login to bypass auth hang');
      _navigateToLogin();
    });
  }

  void _checkNavigationState() {
    if (!mounted || _hasNavigated) return;
    
    final authState = context.read<AuthBloc>().state;
    
    print('SplashScreen: Current auth state: ${authState.runtimeType}');
    
    if (authState is AuthAuthenticated) {
      _navigateToHome();
    } else if (authState is AuthUnauthenticated) {
      _navigateToLogin();
    }
    // If AuthLoading, wait for BlocListener to handle state change
  }

  void _navigateToHome() {
    if (!_hasNavigated && mounted) {
      _hasNavigated = true;
      Navigator.of(context).pushReplacementNamed(AppRouter.home);
    }
  }

  void _navigateToLogin() {
    if (!_hasNavigated && mounted) {
      _hasNavigated = true;
      Navigator.of(context).pushReplacementNamed(AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (!mounted || _hasNavigated) return;
        
        print('SplashScreen: AuthBloc state changed to: ${state.runtimeType}');
        
        if (state is AuthAuthenticated) {
          _navigateToHome();
        } else if (state is AuthUnauthenticated) {
          _navigateToLogin();
        }
      },
      child: Scaffold(
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
                    Icons.play_circle_filled,
                    size: 80,
                    color: Colors.red,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // App Title
                Text(
                  'YouTube Shorts\nCreator',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Subtitle
                Text(
                  'Create amazing shorts with AI',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Loading indicator
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    if (state is AuthLoading) {
                      return Column(
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading...',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 
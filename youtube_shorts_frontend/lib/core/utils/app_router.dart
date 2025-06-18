import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/create_short/screens/create_short_screen.dart';
import '../../features/jobs/screens/jobs_list_screen.dart';
import '../../features/jobs/screens/job_details_screen.dart';
import '../../features/upload/bloc/upload_bloc.dart';
import '../../features/jobs/bloc/jobs_bloc.dart';
import '../splash/splash_screen.dart';
import '../home/home_screen.dart';
import '../di/service_locator.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String createShort = '/create-short';
  static const String jobsList = '/jobs';
  static const String jobDetails = '/job-details';
  
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
        
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
        
      case register:
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
          settings: settings,
        );
        
      case home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );
        
      case createShort:
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider<UploadBloc>(
                create: (_) => getIt<UploadBloc>(),
              ),
              BlocProvider<JobsBloc>(
                create: (_) => getIt<JobsBloc>(),
              ),
            ],
            child: const CreateShortScreen(),
          ),
          settings: settings,
        );
        
      case jobsList:
        return MaterialPageRoute(
          builder: (_) => BlocProvider<JobsBloc>(
            create: (_) => getIt<JobsBloc>(),
            child: const JobsListScreen(),
          ),
          settings: settings,
        );
        
      case jobDetails:
        final jobId = settings.arguments as String?;
        if (jobId == null) {
          return _errorRoute('Job ID is required');
        }
        return MaterialPageRoute(
          builder: (_) => JobDetailsScreen(jobId: jobId),
          settings: settings,
        );
        
      default:
        return _errorRoute('Route not found: ${settings.name}');
    }
  }
  
  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(_).pushReplacementNamed(home),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
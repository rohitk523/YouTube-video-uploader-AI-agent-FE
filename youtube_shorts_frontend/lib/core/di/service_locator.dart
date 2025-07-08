import 'package:get_it/get_it.dart';
import '../network/api_client.dart';
import '../../features/auth/repository/auth_repository.dart';
import '../../features/auth/repository/secret_repository.dart';
import '../../features/upload/repository/upload_repository.dart';
import '../../features/jobs/repository/jobs_repository.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/upload/bloc/upload_bloc.dart';
import '../../features/jobs/bloc/jobs_bloc.dart';
import '../../features/videos/repository/video_repository.dart';
import '../../features/videos/bloc/video_bloc.dart';

final getIt = GetIt.instance;

class ServiceLocator {
  static Future<void> setup() async {
    // Core services
    getIt.registerLazySingleton<ApiClient>(() => ApiClient());
    
    // Repositories
    getIt.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(getIt<ApiClient>()),
    );
    
    getIt.registerLazySingleton<SecretRepository>(
      () => SecretRepositoryImpl(getIt<ApiClient>()),
    );
    
    getIt.registerLazySingleton<UploadRepository>(
      () => UploadRepositoryImpl(getIt<ApiClient>()),
    );
    
    getIt.registerLazySingleton<JobsRepository>(
      () => JobsRepositoryImpl(getIt<ApiClient>()),
    );
    
    // Video related
    getIt.registerLazySingleton<VideoRepository>(
      () => VideoRepository(getIt<ApiClient>()),
    );
    
    // BLoCs - registered as factories so each screen gets a fresh instance if needed
    getIt.registerFactory<AuthBloc>(
      () => AuthBloc(getIt<AuthRepository>()),
    );
    
    getIt.registerFactory<UploadBloc>(
      () => UploadBloc(getIt<UploadRepository>()),
    );
    
    getIt.registerFactory<JobsBloc>(
      () => JobsBloc(getIt<JobsRepository>()),
    );
    
    getIt.registerFactory<VideoBloc>(
      () => VideoBloc(getIt<VideoRepository>()),
    );
  }
  
  static void reset() {
    getIt.reset();
  }
} 
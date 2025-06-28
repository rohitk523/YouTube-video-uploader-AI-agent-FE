import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_manager.dart';
import 'core/utils/app_router.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Setup dependency injection
  await ServiceLocator.setup();
  
  // Initialize theme manager
  final themeManager = ThemeManager();
  await themeManager.loadTheme();
  
  runApp(YouTubeShortsApp(themeManager: themeManager));
}

class YouTubeShortsApp extends StatelessWidget {
  final ThemeManager themeManager;
  
  const YouTubeShortsApp({super.key, required this.themeManager});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: themeManager,
      child: Consumer<ThemeManager>(
        builder: (context, themeManager, child) {
          return BlocProvider(
            create: (context) => getIt<AuthBloc>()..add(AuthCheckRequested()),
            child: MaterialApp(
              title: 'YouTube Shorts Creator',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeManager.themeMode,
              onGenerateRoute: AppRouter.generateRoute,
              initialRoute: AppRouter.splash,
              debugShowCheckedModeBanner: false,
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_event.dart';
import '../../features/auth/bloc/auth_state.dart';
import '../../features/videos/bloc/video_bloc.dart';
import '../../features/videos/screens/video_library_screen.dart';
import '../utils/app_router.dart';
import '../di/service_locator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushReplacementNamed(AppRouter.login);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('YouTube Shorts Creator'),
          actions: [
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthAuthenticated) {
                  return PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'logout') {
                        context.read<AuthBloc>().add(AuthLogoutRequested());
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'profile',
                        child: Row(
                          children: [
                            const Icon(Icons.person),
                            const SizedBox(width: 8),
                            Text(state.user.displayName),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout),
                            SizedBox(width: 8),
                            Text('Logout'),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      margin: const EdgeInsets.only(right: 16),
                      child: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          state.user.displayName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: const [
            _HomeTab(),
            _JobsTab(),
            _VideosTab(),
            _ProfileTab(),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.work),
              label: 'Jobs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.video_library),
              label: 'Videos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
        floatingActionButton: _currentIndex == 0
            ? FloatingActionButton.extended(
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRouter.createShort);
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Short'),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              )
            : null,
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome card
          Card(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.play_circle_filled,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome to YouTube Shorts Creator!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create amazing YouTube Shorts with AI-powered tools',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Quick actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _QuickActionCard(
                icon: Icons.video_call,
                title: 'Create Short',
                subtitle: 'Upload video & transcript',
                onTap: () {
                  Navigator.of(context).pushNamed(AppRouter.createShort);
                },
              ),
              _QuickActionCard(
                icon: Icons.list,
                title: 'View Jobs',
                subtitle: 'Check processing status',
                onTap: () {
                  Navigator.of(context).pushNamed(AppRouter.jobsList);
                },
              ),
              _QuickActionCard(
                icon: Icons.upload_file,
                title: 'Upload Video',
                subtitle: 'Quick video upload',
                onTap: () {
                  Navigator.of(context).pushNamed(AppRouter.createShort);
                },
              ),
              _QuickActionCard(
                icon: Icons.settings_voice,
                title: 'Voice Options',
                subtitle: 'Choose AI voice',
                onTap: () {
                  // TODO: Show voice selection dialog
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Recent activity (placeholder)
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No recent activity. Create your first YouTube Short to get started!',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobsTab extends StatelessWidget {
  const _JobsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Jobs Tab - Will show job list'),
    );
  }
}

class _VideosTab extends StatelessWidget {
  const _VideosTab();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<VideoBloc>(),
      child: const VideoLibraryScreen(),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Profile Tab - Will show user profile'),
    );
  }
} 
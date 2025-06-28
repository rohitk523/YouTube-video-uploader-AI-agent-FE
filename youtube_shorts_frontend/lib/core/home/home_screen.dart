import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/bloc/auth_event.dart';
import '../../features/auth/bloc/auth_state.dart';
import '../../features/jobs/screens/jobs_list_screen.dart';
import '../../features/jobs/bloc/jobs_bloc.dart';
import '../../features/create_short/screens/create_short_screen.dart';
import '../../features/upload/bloc/upload_bloc.dart';
import '../../features/videos/bloc/video_bloc.dart';
import '../utils/app_router.dart';
import '../di/service_locator.dart';
import 'claude_layout.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // Start with Home (Create Short) tab

  static const List<NavigationItem> _navigationItems = [
    NavigationItem(icon: Icons.home_outlined, label: 'Home'),
    NavigationItem(icon: Icons.work_outline, label: 'Jobs'),
    NavigationItem(icon: Icons.person_outline, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushReplacementNamed(AppRouter.login);
        }
      },
      child: ClaudeLayout(
        title: 'YouTube Shorts Creator',
        currentIndex: _currentIndex,
        navigationItems: _navigationItems,
        onNavigationChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        appBarActions: [
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return _buildUserMenu(context, state);
              }
              return const SizedBox.shrink();
            },
          ),
        ],
        body: _buildCurrentPage(),
      ),
    );
  }

  Widget _buildUserMenu(BuildContext context, AuthAuthenticated state) {
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
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF2D2D2D) 
              : const Color(0xFFE5E7EB),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                state.user.displayName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              state.user.displayName,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPage() {
    return IndexedStack(
      index: _currentIndex,
      children: [
          // Home Tab (Create Short) with improved margins
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            child: MultiBlocProvider(
              providers: [
                BlocProvider<UploadBloc>(
                  create: (_) => getIt<UploadBloc>(),
                ),
                BlocProvider<JobsBloc>(
                  create: (_) => getIt<JobsBloc>(),
                ),
                BlocProvider<VideoBloc>(
                  create: (_) => getIt<VideoBloc>(),
                ),
              ],
              child: const _CreateShortWrapper(),
            ),
          ),
          
          // Jobs Tab with improved margins
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            child: BlocProvider<JobsBloc>(
              create: (_) => getIt<JobsBloc>(),
              child: const _JobsWrapper(),
            ),
          ),
          
          // Profile Tab with improved margins
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            child: const _ProfileTab(),
          ),
        ],
      );
  }
}

// Wrapper widgets to remove their own app bars since we're using ClaudeLayout
class _JobsWrapper extends StatelessWidget {
  const _JobsWrapper();

  @override
  Widget build(BuildContext context) {
    return const JobsListScreen(showAppBar: false);
  }
}

class _CreateShortWrapper extends StatelessWidget {
  const _CreateShortWrapper();

  @override
  Widget build(BuildContext context) {
    return const CreateShortScreen(showAppBar: false);
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header Card
                Card(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: state.user.profilePictureUrl != null
                              ? ClipOval(
                                  child: Image.network(
                                    state.user.profilePictureUrl!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Text(
                                        state.user.displayName.substring(0, 1).toUpperCase(),
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onPrimary,
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Text(
                                  state.user.displayName.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.user.displayName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.user.email,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              state.user.isVerified ? Icons.verified : Icons.pending,
                              color: state.user.isVerified 
                                ? const Color(0xFF059669) 
                                : const Color(0xFFD97706),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              state.user.isVerified ? 'Verified' : 'Pending Verification',
                              style: TextStyle(
                                color: state.user.isVerified 
                                  ? const Color(0xFF059669) 
                                  : const Color(0xFFD97706),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Account Information Section
                Text(
                  'Account Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Card(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildInfoRow(context, 'Username', state.user.username ?? 'Not set'),
                        const Divider(),
                        _buildInfoRow(context, 'First Name', state.user.firstName ?? 'Not set'),
                        const Divider(),
                        _buildInfoRow(context, 'Last Name', state.user.lastName ?? 'Not set'),
                        const Divider(),
                        _buildInfoRow(context, 'Provider', state.user.provider ?? 'Local'),
                        const Divider(),
                        _buildInfoRow(context, 'Member Since', _formatDate(state.user.createdAt)),
                        if (state.user.lastLoginAt != null) ...[
                          const Divider(),
                          _buildInfoRow(context, 'Last Login', _formatDate(state.user.lastLoginAt!)),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // Statistics Section
                Text(
                  'Statistics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Card(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(context, 'Videos Created', '0'),
                        _buildStatCard(context, 'Jobs Completed', '0'),
                        _buildStatCard(context, 'YouTube Uploads', '0'),
                      ],
                    ),
                  ),
                ),
                
                // Action Buttons
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Edit profile feature coming soon!')),
                            );
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Profile'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Change password feature coming soon!')),
                            );
                          },
                          icon: const Icon(Icons.lock),
                          label: const Text('Change Password'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            _showLogoutConfirmation(context);
                          },
                          icon: const Icon(Icons.logout),
                          label: const Text('Logout'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            side: const BorderSide(color: Color(0xFFDC2626)),
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
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
  
  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthBloc>().add(AuthLogoutRequested());
              },
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
} 
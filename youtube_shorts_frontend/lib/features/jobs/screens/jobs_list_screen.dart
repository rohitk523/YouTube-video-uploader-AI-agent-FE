import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'dart:html' as html;
import '../../../core/di/service_locator.dart';
import '../../../core/constants/api_constants.dart';
import '../../../shared/models/job_models.dart';
import '../bloc/jobs_bloc.dart';
import '../bloc/jobs_event.dart';
import '../bloc/jobs_state.dart';
import '../repository/jobs_repository.dart';
import '../../../core/network/api_client.dart';
import 'job_details_screen.dart';

class JobsListScreen extends StatefulWidget {
  final bool showAppBar;
  
  const JobsListScreen({super.key, this.showAppBar = true});

  @override
  State<JobsListScreen> createState() => _JobsListScreenState();
}

class _JobsListScreenState extends State<JobsListScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger initial load of jobs when screen is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<JobsBloc>().add(const LoadJobsEvent());
      }
    });
  }

  Future<void> _downloadProcessedVideo(String jobId) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Starting download...'),
            backgroundColor: Colors.blue,
          ),
        );
      }

      if (kIsWeb) {
        // For web platform, use ApiClient to get the file with authentication
        final apiClient = getIt<ApiClient>();
        final downloadUrl = ApiConstants.downloadJobVideo(jobId);
        
        // Make an authenticated request to get the video file
        final response = await apiClient.get(
          downloadUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        
        // Create a blob and download it
        final bytes = response.data as List<int>;
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        
        html.AnchorElement(href: url)
          ..setAttribute('download', 'processed_video_$jobId.mp4')
          ..style.display = 'none'
          ..click();
          
        // Clean up the object URL
        html.Url.revokeObjectUrl(url);
      } else {
        // For mobile platforms, use the repository method
        // Note: You'll need to implement file picker to choose save location
        final jobsRepository = getIt<JobsRepository>();
        final savePath = '/tmp/processed_video_$jobId.mp4'; // Temporary path
        await jobsRepository.downloadProcessedVideo(jobId, savePath);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the existing JobsBloc from parent context instead of creating a new one
    return Scaffold(
        appBar: widget.showAppBar ? AppBar(
          title: const Text('Processing Jobs'),
          actions: [
            BlocBuilder<JobsBloc, JobsState>(
              builder: (context, state) {
                return IconButton(
                  onPressed: () {
                    context.read<JobsBloc>().add(RefreshJobsEvent());
                  },
                  icon: const Icon(Icons.refresh),
                );
              },
            ),
          ],
        ) : null,
        body: BlocBuilder<JobsBloc, JobsState>(
          builder: (context, state) {
            // Handle JobDeleted state right in the builder to test
            if (state is JobDeleted) {
              
              // Show success message
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Job deleted successfully!'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 3),
                  ),
                );
                
                // Trigger refresh after showing snackbar
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (context.mounted) {
                    context.read<JobsBloc>().add(LoadJobsEvent());
                  }
                });
              });
              
              // Show loading while refresh is pending
              return const Center(child: CircularProgressIndicator());
            }
            
            if (state is JobsLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (state is JobsListLoaded) {
              if (state.jobs.isEmpty) {
                return _buildEmptyState();
              }
              return _buildJobsList(state.jobs);
            } else if (state is JobsError) {
              return _buildErrorState(state.message);
            }
            return _buildEmptyState();
          },
        ),
      );
  }

  Widget _buildJobsList(List<JobListItem> jobs) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<JobsBloc>().add(RefreshJobsEvent());
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          final job = jobs[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: _buildJobCard(job),
          );
        },
      ),
    );
  }

  Widget _buildJobCard(JobListItem job) {
    return Card(
      margin: const EdgeInsets.all(0),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => JobDetailsScreen(jobId: job.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(job.status.name),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Job ID: ${job.id}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Created: ${_formatDateTime(job.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
              _buildProgressSection(job),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Show download or YouTube button for completed jobs
                  if (job.status.name.toLowerCase() == 'completed') ...[
                    if (job.mockMode) ...[
                      // Mock mode: Show download button
                      TextButton.icon(
                        onPressed: () => _downloadProcessedVideo(job.id),
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('Download'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                      ),
                    ] else if (job.youtubeUrl != null) ...[
                      // Regular mode: Show YouTube link
                      TextButton.icon(
                        onPressed: () async {
                          final uri = Uri.parse(job.youtubeUrl!);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text('YouTube'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ],
                  if (_canRetry(job.status.name))
                    TextButton.icon(
                      onPressed: () => _showRetryDialog(job),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Retry'),
                    ),
                  if (_canDelete(job.status.name))
                    TextButton.icon(
                      onPressed: () => _showDeleteDialog(job),
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => JobDetailsScreen(jobId: job.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('Details'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        icon = Icons.schedule;
        break;
      case 'processing':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        icon = Icons.sync;
        break;
      case 'completed':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
        break;
      case 'failed':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        icon = Icons.error;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(JobListItem job) {
    if (job.status.name.toLowerCase() == 'processing') {
      // Show progress bar with actual progress if available
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Processing...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${job.progress}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: job.progress / 100.0,
            backgroundColor: Colors.blue.shade50,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
          ),
        ],
      );
    } else if (job.status.name.toLowerCase() == 'completed') {
      return Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
          const SizedBox(width: 4),
          Text(
            'Completed',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          if (job.mockMode) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download, size: 12, color: Colors.blue.shade600),
                  const SizedBox(width: 2),
                  Text(
                    'Mock',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (job.youtubeUrl != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow, size: 12, color: Colors.red.shade600),
                  const SizedBox(width: 2),
                  Text(
                    'YouTube',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_outline,
              size: 80,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Jobs Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create your first YouTube Short to see processing jobs here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed('/create-short');
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Short'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: const Color(0xFFDC2626),
            ),
            const SizedBox(height: 24),
            Text(
              'Error Loading Jobs',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            BlocBuilder<JobsBloc, JobsState>(
              builder: (context, state) {
                return FilledButton.icon(
                  onPressed: () {
                    context.read<JobsBloc>().add(RefreshJobsEvent());
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(dateTime);
    }
  }

  bool _canRetry(String status) {
    return status.toLowerCase() == 'failed';
  }

  bool _canDelete(String status) {
    // Allow deletion for failed, completed, and pending jobs
    // Don't allow deletion of currently processing jobs
    return !['processing'].contains(status.toLowerCase());
  }

  void _showRetryDialog(JobListItem job) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Retry Job'),
        content: Text(
          'Are you sure you want to retry processing for "${job.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // TODO: Implement retry functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Retry functionality coming soon')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(JobListItem job) {
    final jobsBloc = context.read<JobsBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Job'),
        content: Text(
          'Are you sure you want to delete the job "${job.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              jobsBloc.add(DeleteJobEvent(job.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
} 
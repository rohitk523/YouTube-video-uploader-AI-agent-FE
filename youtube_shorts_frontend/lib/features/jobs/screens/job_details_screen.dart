import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/di/service_locator.dart';
import '../../../shared/models/job_models.dart';
import '../bloc/jobs_bloc.dart';
import '../bloc/jobs_event.dart';
import '../bloc/jobs_state.dart';

class JobDetailsScreen extends StatefulWidget {
  final String jobId;
  
  const JobDetailsScreen({
    super.key,
    required this.jobId,
  });

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  late JobsBloc _jobsBloc;

  @override
  void initState() {
    super.initState();
    _jobsBloc = getIt<JobsBloc>();
    _jobsBloc.add(LoadJobDetailsEvent(widget.jobId));
    // Start polling for status updates if job is processing
    _jobsBloc.add(StartJobPollingEvent(widget.jobId));
  }

  @override
  void dispose() {
    _jobsBloc.add(StopJobPollingEvent());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<JobsBloc>.value(
      value: _jobsBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Job Details'),
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          actions: [
            BlocBuilder<JobsBloc, JobsState>(
              builder: (context, state) {
                return IconButton(
                  onPressed: () {
                    _jobsBloc.add(LoadJobDetailsEvent(widget.jobId));
                  },
                  icon: const Icon(Icons.refresh),
                );
              },
            ),
          ],
        ),
        body: BlocListener<JobsBloc, JobsState>(
          listener: (context, state) {
            if (state is JobDeleted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Job deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is JobsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${state.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: BlocBuilder<JobsBloc, JobsState>(
            builder: (context, state) {
              if (state is JobsLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else if (state is JobDetailsLoaded) {
                return _buildJobDetails(state.job);
              } else if (state is JobStatusUpdated) {
                // Update the UI with new status while keeping job details
                return BlocBuilder<JobsBloc, JobsState>(
                  buildWhen: (previous, current) => current is JobDetailsLoaded,
                  builder: (context, jobState) {
                    if (jobState is JobDetailsLoaded) {
                      // Create updated job with new status
                      final updatedJob = JobResponse(
                        jobId: jobState.job.jobId,
                        videoUploadId: jobState.job.videoUploadId,
                        transcriptUploadId: jobState.job.transcriptUploadId,
                        outputTitle: jobState.job.outputTitle,
                        outputDescription: jobState.job.outputDescription,
                        voice: jobState.job.voice,
                        autoUpload: jobState.job.autoUpload,
                        status: state.status.status,
                        progressPercentage: state.status.progressPercentage,
                        errorMessage: state.status.errorMessage,
                        youtubeUrl: state.status.youtubeUrl ?? jobState.job.youtubeUrl,
                        outputVideoUrl: state.status.outputVideoUrl ?? jobState.job.outputVideoUrl,
                        createdAt: jobState.job.createdAt,
                        updatedAt: state.status.lastUpdated ?? jobState.job.updatedAt,
                      );
                      return _buildJobDetails(updatedJob);
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                );
              } else if (state is JobsError) {
                return _buildErrorState(state.message);
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );
  }

  Widget _buildJobDetails(JobResponse job) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(job),
          const SizedBox(height: 16),
          _buildStatusCard(job),
          const SizedBox(height: 16),
          _buildProgressCard(job),
          const SizedBox(height: 16),
          _buildDetailsCard(job),
          if (job.videoUploadId != null || job.transcriptUploadId != null) ...[
            const SizedBox(height: 16),
            _buildUploadInfoCard(job),
          ],
          if (job.outputVideoUrl != null || job.youtubeUrl != null) ...[
            const SizedBox(height: 16),
            _buildResultsCard(job),
          ],
          if (job.errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildErrorCard(job.errorMessage!),
          ],
          const SizedBox(height: 16),
          _buildActionsCard(job),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(JobResponse job) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.outputTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(job.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Job ID: ${job.jobId}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontFamily: 'monospace',
              ),
            ),
            if (job.outputDescription != null) ...[
              const SizedBox(height: 12),
              Text(
                job.outputDescription!,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(JobResponse job) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Current Status', job.status.toUpperCase()),
            const SizedBox(height: 8),
            _buildInfoRow('Created', _formatDateTime(job.createdAt)),
            const SizedBox(height: 8),
            _buildInfoRow('Last Updated', _formatDateTime(job.updatedAt)),
            if (job.progressPercentage != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Progress', '${job.progressPercentage!.toInt()}%'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(JobResponse job) {
    final isProcessing = job.status.toLowerCase() == 'processing';
    final progress = job.progressPercentage;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Processing Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (isProcessing || progress != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isProcessing ? 'Processing your video...' : 'Processing completed',
                          style: TextStyle(
                            fontSize: 14,
                            color: isProcessing ? Colors.blue.shade700 : Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress != null ? progress / 100 : null,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isProcessing ? Colors.blue.shade600 : Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (progress != null) ...[
                    const SizedBox(width: 16),
                    Text(
                      '${progress.toInt()}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isProcessing ? Colors.blue.shade700 : Colors.green.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Icon(
                    _getStatusIcon(job.status),
                    color: _getStatusColor(job.status),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusMessage(job.status),
                    style: TextStyle(
                      fontSize: 16,
                      color: _getStatusColor(job.status),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(JobResponse job) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Job Configuration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Voice', job.voice?.toUpperCase() ?? 'Default'),
            const SizedBox(height: 8),
            _buildInfoRow('Auto Upload to YouTube', job.autoUpload ? 'Enabled' : 'Disabled'),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadInfoCard(JobResponse job) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (job.videoUploadId != null) ...[
                  Expanded(
                    child: _buildUploadChip(
                      'Video Upload',
                      job.videoUploadId!,
                      Icons.videocam,
                      Colors.red.shade100,
                      Colors.red.shade700,
                    ),
                  ),
                ],
                if (job.transcriptUploadId != null) ...[
                  if (job.videoUploadId != null) const SizedBox(width: 12),
                  Expanded(
                    child: _buildUploadChip(
                      'Transcript Upload',
                      job.transcriptUploadId!,
                      Icons.description,
                      Colors.blue.shade100,
                      Colors.blue.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard(JobResponse job) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Results',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (job.outputVideoUrl != null) ...[
              _buildResultItem(
                'Processed Video',
                job.outputVideoUrl!,
                Icons.video_file,
                Colors.purple.shade600,
                () {
                  // TODO: Download or view processed video
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Downloading video...')),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
            if (job.youtubeUrl != null) ...[
              _buildResultItem(
                'YouTube Video',
                job.youtubeUrl!,
                Icons.play_circle_filled,
                Colors.red.shade600,
                () {
                  // TODO: Open YouTube URL
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening YouTube...')),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String errorMessage) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error, color: Colors.red.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Error Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Text(
                errorMessage,
                style: TextStyle(
                  color: Colors.red.shade800,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(JobResponse job) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (_canRetry(job.status)) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showRetryDialog(job),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (_canDelete(job.status)) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showDeleteDialog(job),
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadChip(
    String label,
    String uploadId,
    IconData icon,
    Color backgroundColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            uploadId.length > 12 ? '${uploadId.substring(0, 12)}...' : uploadId,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(
    String label,
    String url,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          url,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Icon(Icons.open_in_new, color: color),
        onTap: onTap,
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
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Job Details',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red.shade500,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _jobsBloc.add(LoadJobDetailsEvent(widget.jobId));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, y • h:mm a').format(dateTime);
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'processing':
        return Icons.sync;
      case 'completed':
        return Icons.check_circle;
      case 'failed':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade600;
      case 'processing':
        return Colors.blue.shade600;
      case 'completed':
        return Colors.green.shade600;
      case 'failed':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _getStatusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Job is waiting to be processed';
      case 'processing':
        return 'Job is currently being processed';
      case 'completed':
        return 'Job completed successfully';
      case 'failed':
        return 'Job processing failed';
      default:
        return 'Unknown status';
    }
  }

  bool _canRetry(String status) {
    return status.toLowerCase() == 'failed';
  }

  bool _canDelete(String status) {
    return ['failed', 'completed'].contains(status.toLowerCase());
  }

  void _showRetryDialog(JobResponse job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retry Job'),
        content: Text(
          'Are you sure you want to retry processing for "${job.outputTitle}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
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

  void _showDeleteDialog(JobResponse job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Job'),
        content: Text(
          'Are you sure you want to delete the job "${job.outputTitle}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _jobsBloc.add(DeleteJobEvent(job.jobId));
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
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../core/config/environment.dart';

class ApiStatusWidget extends StatefulWidget {
  const ApiStatusWidget({Key? key}) : super(key: key);

  @override
  State<ApiStatusWidget> createState() => _ApiStatusWidgetState();
}

class _ApiStatusWidgetState extends State<ApiStatusWidget> {
  final ApiClient _apiClient = ApiClient();

  @override
  Widget build(BuildContext context) {
    if (!EnvironmentConfig.isProduction) {
      return const SizedBox.shrink(); // Don't show in development
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _apiClient.isUsingFallback 
            ? Colors.orange.withOpacity(0.1)
            : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _apiClient.isUsingFallback 
              ? Colors.orange 
              : Colors.green,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _apiClient.isUsingFallback 
                ? Icons.warning_rounded
                : Icons.check_circle_rounded,
            size: 16,
            color: _apiClient.isUsingFallback 
                ? Colors.orange 
                : Colors.green,
          ),
          const SizedBox(width: 6),
          Text(
            _apiClient.isUsingFallback 
                ? 'Using Backup API'
                : 'Primary API Active',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _apiClient.isUsingFallback 
                  ? Colors.orange.shade700
                  : Colors.green.shade700,
            ),
          ),
          if (_apiClient.isUsingFallback) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  _apiClient.resetToPrimary();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Switched back to primary API'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Reset',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
} 
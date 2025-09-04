import 'package:flutter/material.dart';

class ConnectionOverlay extends StatelessWidget {
  final bool isReconnecting;
  final VoidCallback? onRetry;

  const ConnectionOverlay({
    super.key,
    this.isReconnecting = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isReconnecting) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text(
                  'Reconnecting...',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please wait while we restore your connection',
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                const Icon(Icons.signal_wifi_off, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Connection Lost',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Check your internet connection',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (onRetry != null)
                  ElevatedButton(
                    onPressed: onRetry,
                    child: const Text('Retry Connection'),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

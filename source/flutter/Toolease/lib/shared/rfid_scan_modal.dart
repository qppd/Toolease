import 'package:flutter/material.dart';
import '../services/websocket_service.dart';
import 'dart:async';

/// Reusable RFID scanning modal with loading animation
/// Shows loading state, handles timeout, and displays appropriate messages
class RFIDScanModal {
  /// Show RFID scanning modal and return scanned tag ID
  /// Returns null if cancelled or error occurs
  static Future<String?> show({
    required BuildContext context,
    required WebSocketService websocketService,
    Duration timeout = const Duration(seconds: 20),
    String? customMessage,
  }) async {
    if (!websocketService.isConnected) {
      _showErrorDialog(
        context,
        'RFID scanner not connected.',
        'Please ensure the ESP32 scanner is connected via WiFi.',
      );
      return null;
    }

    String? scannedTagId;
    bool isScanning = true;
    StreamSubscription? messageSubscription;

    // Show the modal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return WillPopScope(
          onWillPop: () async => false, // Prevent back button
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated RFID Icon
                  const _PulsingRFIDIcon(),
                  const SizedBox(height: 24),
                  // Message
                  Text(
                    customMessage ?? 'Waiting for RFID scan...',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Please tap or scan the RFID tag',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Progress indicator
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  // Cancel button
                  TextButton(
                    onPressed: () {
                      isScanning = false;
                      messageSubscription?.cancel();
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // Listen for messages from WebSocket
    final completer = Completer<String?>();
    messageSubscription = websocketService.stream?.listen((message) {
      if (!isScanning) return;
      
      if (message == 'TIMEOUT') {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      } else if (message != 'WRITE_SUCCESS' && message != 'WRITE_ERROR' && message != 'CONNECTED') {
        // Assume it's a tag ID
        if (!completer.isCompleted) {
          completer.complete(message.toString().trim());
        }
      }
    });

    // Start scanning
    try {
      scannedTagId = await websocketService.scanRFID(timeout: timeout);
      
      if (context.mounted && isScanning) {
        Navigator.of(context).pop(); // Close modal on success/timeout
        
        if (scannedTagId == null || scannedTagId.isEmpty) {
          _showErrorDialog(
            context,
            'Scan Timeout',
            'No RFID tag detected within ${timeout.inSeconds} seconds.',
          );
          scannedTagId = null; // Ensure null is returned
        }
      }
    } catch (e) {
      if (context.mounted && isScanning) {
        Navigator.of(context).pop(); // Close modal
        _showErrorDialog(
          context,
          'Scan Error',
          'Failed to scan RFID tag. Please try again.',
        );
      }
    } finally {
      messageSubscription?.cancel();
    }

    return isScanning ? scannedTagId : null;
  }

  static void _showErrorDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Pulsing RFID icon animation widget
class _PulsingRFIDIcon extends StatefulWidget {
  const _PulsingRFIDIcon();

  @override
  State<_PulsingRFIDIcon> createState() => _PulsingRFIDIconState();
}

class _PulsingRFIDIconState extends State<_PulsingRFIDIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.nfc,
              size: 50,
              color: Theme.of(context).primaryColor,
            ),
          ),
        );
      },
    );
  }
}

/// Success modal for showing scan result
class RFIDScanSuccess {
  static void show(
    BuildContext context,
    String tagId, {
    VoidCallback? onDismiss,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 60,
            ),
            const SizedBox(height: 16),
            const Text(
              'RFID Tag Scanned',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tagId,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDismiss?.call();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/websocket_service.dart';

// Singleton WebSocket service instance
final _websocketServiceInstance = WebSocketService();

// Provider for WebSocketService instance - uses the same instance as the connection provider
final websocketServiceProvider = Provider<WebSocketService>((ref) {
  return _websocketServiceInstance;
});

// Provider for connection status
final websocketConnectionProvider = StateNotifierProvider<WebSocketConnectionNotifier, bool>((ref) {
  return WebSocketConnectionNotifier(_websocketServiceInstance);
});

class WebSocketConnectionNotifier extends StateNotifier<bool> {
  final WebSocketService _service;
  StreamSubscription? _connectionSubscription;
  Timer? _retryTimer;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  WebSocketConnectionNotifier(this._service) : super(false) {
    _attemptConnection();
  }

  void _attemptConnection() async {
    if (_retryCount >= _maxRetries) {
      print('[Provider] Max retries reached. Stopping auto-connect.');
      _retryCount = 0;
      return;
    }
    
    try {
      print('[Provider] Connection attempt ${_retryCount + 1}/$_maxRetries');
      _service.connect();
      
      // Listen to the stream to detect successful connection
      _connectionSubscription?.cancel();
      _connectionSubscription = _service.stream?.listen(
        (event) {
          // Got data - definitely connected
          if (!state) {
            state = true;
            _retryCount = 0; // Reset retry count on success
            _retryTimer?.cancel();
            print('[Provider] ✓ Connected - received: $event');
          }
        },
        onError: (e) {
          if (state) {
            state = false;
            print('[Provider] Connection lost: $e');
          }
        },
        onDone: () {
          if (state) {
            state = false;
            print('[Provider] Connection ended');
          }
        },
      );
      
      // Wait for connection to establish
      await Future.delayed(const Duration(milliseconds: 2000));
      
      // Check connection status after delay
      if (_service.isConnected && !state) {
        state = true;
        _retryCount = 0; // Reset retry count on success
        print('[Provider] ✓ Connection ready');
      } else if (!_service.isConnected && !state) {
        // Connection failed, schedule retry
        _retryCount++;
        if (_retryCount < _maxRetries) {
          print('[Provider] Connection failed. Retrying in 2 seconds...');
          _retryTimer = Timer(const Duration(seconds: 2), () {
            _attemptConnection();
          });
        }
      }
    } catch (e) {
      state = false;
      _retryCount++;
      print('[Provider] Connection exception: $e');
      
      if (_retryCount < _maxRetries) {
        print('[Provider] Retrying in 2 seconds...');
        _retryTimer = Timer(const Duration(seconds: 2), () {
          _attemptConnection();
        });
      }
    }
  }

  void reconnect() {
    print('[Provider] Manual reconnect requested');
    _retryTimer?.cancel();
    _retryCount = 0;
    state = false;
    _attemptConnection();
  }

  void disconnect() {
    _retryTimer?.cancel();
    _connectionSubscription?.cancel();
    _service.disconnect();
    _retryCount = 0;
    state = false;
  }
  
  @override
  void dispose() {
    _retryTimer?.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }
}

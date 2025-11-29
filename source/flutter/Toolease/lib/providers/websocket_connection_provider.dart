import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/websocket_service.dart';

final websocketConnectionProvider = StateNotifierProvider<WebSocketConnectionNotifier, bool>((ref) {
  return WebSocketConnectionNotifier();
});

class WebSocketConnectionNotifier extends StateNotifier<bool> {
  WebSocketService? _service;

  WebSocketConnectionNotifier() : super(false) {
    _service = WebSocketService();
    _checkConnection();
  }

  void _checkConnection() async {
    try {
      _service!.connect();
      // Try to listen for a short time to see if connection is open
      _service!.stream?.listen((event) {
        if (!state) state = true;
      }, onError: (e) {
        state = false;
      }, onDone: () {
        state = false;
      });
      // If no error after a short delay, consider connected
      await Future.delayed(const Duration(seconds: 2));
      if (!state) state = true;
    } catch (e) {
      state = false;
    }
  }

  void reconnect() {
    state = false;
    _checkConnection();
  }

  void disconnect() {
    _service?.disconnect();
    state = false;
  }
}

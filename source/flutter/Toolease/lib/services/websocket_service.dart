import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketService {
  WebSocketChannel? _channel;
  StreamController<dynamic>? _broadcastController;
  final String esp32Ip;
  final int port;
  bool _isConnected = false;
  Timer? _reconnectTimer;

  WebSocketService({
    this.esp32Ip = '192.168.4.1', // ESP32 softAP default IP
    this.port = 80, // Changed from 81 to 80 for ESPAsyncWebServer
  });

  bool get isConnected => _isConnected && _channel != null;

  void connect() {
    // Close existing connection if any
    disconnect();
    
    try {
      print('[WebSocket] Connecting to ws://$esp32Ip/ws');
      
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://$esp32Ip/ws'),
      );
      _broadcastController = StreamController.broadcast();
      
      bool connectionConfirmed = false;
      
      _channel!.stream.listen(
        (event) {
          // Mark as connected when receiving any data
          if (!connectionConfirmed) {
            connectionConfirmed = true;
            _isConnected = true;
            print('[WebSocket] Connection confirmed - received: $event');
          }
          _broadcastController?.add(event);
        },
        onError: (e) {
          print('[WebSocket] Stream error: $e');
          _isConnected = false;
          connectionConfirmed = false;
          _broadcastController?.addError(e);
          _scheduleReconnect();
        },
        onDone: () {
          print('[WebSocket] Stream done (connection closed)');
          _isConnected = false;
          connectionConfirmed = false;
          _scheduleReconnect();
        },
        cancelOnError: false,
      );
      
      // Optimistically assume connected after delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (_channel != null && !connectionConfirmed) {
          _isConnected = true;
          print('[WebSocket] Connection assumed ready');
        }
      });
    } catch (e) {
      print('[WebSocket] Connection exception: $e');
      _isConnected = false;
      _channel = null;
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!_isConnected) {
        print('[WebSocket] Attempting auto-reconnect...');
        connect();
      }
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _isConnected = false;
    _channel?.sink.close(status.goingAway);
    _broadcastController?.close();
    _channel = null;
    _broadcastController = null;
  }

  Stream<dynamic>? get stream => _broadcastController?.stream;

  void sendMessage(String message) {
    print('[WebSocket] Sending message: $message');
    if (!isConnected) {
      print('[WebSocket] ERROR: Not connected, cannot send message');
      throw Exception('WebSocket not connected');
    }
    _channel?.sink.add(message);
    print('[WebSocket] Message sent successfully');
  }

  /// Scan RFID with configurable timeout
  /// Returns the RFID tag ID (Serial No.) on success
  /// Throws exception on timeout or connection error
  Future<String> scanRFID({Duration timeout = const Duration(seconds: 20)}) async {
    print('[WebSocket] scanRFID called, isConnected: $isConnected');
    if (!isConnected) {
      print('[WebSocket] ERROR: Cannot scan, not connected');
      throw Exception('RFID scanner not connected');
    }

    print('[WebSocket] Sending SCAN_RFID command...');
    sendMessage('SCAN_RFID');
    print('[WebSocket] SCAN_RFID command sent, waiting for response...');
    final completer = Completer<String>();
    late StreamSubscription sub;

    sub = stream!.listen(
      (message) {
        if (!completer.isCompleted) {
          // Parse the message from ESP32
          final tagId = message.toString().trim();
          if (tagId.isNotEmpty && tagId != 'ERROR' && tagId != 'TIMEOUT') {
            completer.complete(tagId);
            sub.cancel();
          }
        }
      },
      onError: (e) {
        if (!completer.isCompleted) {
          completer.completeError(e);
          sub.cancel();
        }
      },
    );

    return completer.future.timeout(
      timeout,
      onTimeout: () {
        sub.cancel();
        throw TimeoutException('Scan timed out. Try again.');
      },
    );
  }

  /// Request ESP32 to write data to RFID tag (optional feature)
  Future<bool> writeRFID(String data, {Duration timeout = const Duration(seconds: 15)}) async {
    if (!isConnected) {
      throw Exception('RFID scanner not connected');
    }

    sendMessage('WRITE_RFID:$data');
    final completer = Completer<bool>();
    late StreamSubscription sub;

    sub = stream!.listen(
      (message) {
        if (!completer.isCompleted) {
          final response = message.toString().trim();
          if (response == 'WRITE_SUCCESS') {
            completer.complete(true);
            sub.cancel();
          } else if (response == 'WRITE_ERROR') {
            completer.complete(false);
            sub.cancel();
          }
        }
      },
      onError: (e) {
        if (!completer.isCompleted) {
          completer.complete(false);
          sub.cancel();
        }
      },
    );

    return completer.future.timeout(
      timeout,
      onTimeout: () {
        sub.cancel();
        return false;
      },
    );
  }

  void dispose() {
    disconnect();
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
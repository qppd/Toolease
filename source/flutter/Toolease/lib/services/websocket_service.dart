import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketService {
  WebSocketChannel? _channel;
  StreamController<dynamic>? _broadcastController;
  final String esp32Ip = '192.168.4.1'; // ESP32 softAP default IP
  final int port = 81; // Replace with actual port

  void connect() {
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://$esp32Ip:$port'),
    );
    _broadcastController = StreamController.broadcast();
    _channel!.stream.listen(
      (event) {
        _broadcastController?.add(event);
      },
      onError: (e) {
        _broadcastController?.addError(e);
      },
      onDone: () {
        _broadcastController?.close();
      },
      cancelOnError: true,
    );
  }

  void disconnect() {
    _channel?.sink.close(status.goingAway);
    _broadcastController?.close();
  }

  Stream<dynamic>? get stream => _broadcastController?.stream;

  void sendMessage(String message) {
    _channel?.sink.add(message);
  }

  Future<String> scanRFID() async {
    sendMessage('SCAN_RFID');
    final completer = Completer<String>();
    late StreamSubscription sub;
    sub = stream!.listen((message) {
      if (!completer.isCompleted) {
        completer.complete(message as String);
        sub.cancel();
      }
    }, onError: (e) {
      if (!completer.isCompleted) {
        completer.completeError(e);
        sub.cancel();
      }
    });
    return completer.future.timeout(const Duration(seconds: 10), onTimeout: () {
      sub.cancel();
      throw Exception('No RFID scanned');
    });
  }
}
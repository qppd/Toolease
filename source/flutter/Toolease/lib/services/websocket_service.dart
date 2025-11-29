import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketService {
  WebSocketChannel? _channel;
  final String esp32Ip = '192.168.4.1'; // ESP32 softAP default IP
  final int port = 81; // Replace with actual port

  void connect() {
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://$esp32Ip:$port'),
    );
  }

  void disconnect() {
    _channel?.sink.close(status.goingAway);
  }

  Stream<dynamic>? get stream => _channel?.stream;

  void sendMessage(String message) {
    _channel?.sink.add(message);
  }

  Future<String> scanRFID() async {
    sendMessage('SCAN_RFID');
    // Wait for response
    await for (final message in stream!) {
      return message as String;
    }
    throw Exception('No RFID scanned');
  }
}
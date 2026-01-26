import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../core/constants/api_constants.dart';
import 'package:flutter/foundation.dart';

class SocketService {
  io.Socket? _socket;

  io.Socket? get socket => _socket;

  void connect(String token) {
    if (_socket != null && _socket!.connected) return;

    _socket = io.io(
      ApiConstants.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket']) // Use websocket only
          .setAuth({'Authorization': 'Bearer $token'})
          .enableAutoConnect()
          .build(),
    );

    _socket!.on('connect', (_) {
      debugPrint('Connected to socket server');
    });

    _socket!.on('disconnect', (_) {
      debugPrint('Disconnected from socket server');
    });

    _socket!.on('connectError', (data) {
      debugPrint('Connection Error: $data');
    });

    _socket!.on('error', (data) {
      debugPrint('Socket Error: $data');
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  void on(String event, Function(dynamic) handler) {
    _socket?.on(event, handler);
  }
}

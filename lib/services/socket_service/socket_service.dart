import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../core/constants/api_constants.dart';
import 'package:flutter/foundation.dart';

class SocketService {
  io.Socket? _socket;
  final Map<String, List<Function(dynamic)>> _handlers = {};

  /// Callback khi gặp lỗi authentication (token hết hạn)
  void Function()? onAuthError;

  io.Socket? get socket => _socket;

  void connect(String token) {
    // If socket exists and connected with the same token, do nothing
    if (_socket != null &&
        _socket!.connected &&
        _socket!.io.options?['auth']?['Authorization'] ==
            'Bearer $token') {
      return;
    }

    // If socket exists but token is different, disconnect first
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }

    debugPrint(
      'Connecting to socket with token: ${token.substring(0, 10)}...',
    );
    _socket = io.io(ApiConstants.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'forceNew': true, // Essential for account switching
      'multiplex': false, // Ensure isolated connection
      'auth': {'Authorization': 'Bearer $token'},
    });

    _socket!.on('connect', (_) {
      debugPrint('Connected to socket server');
      // Re-register all handlers
      _handlers.forEach((event, handlers) {
        for (var handler in handlers) {
          _socket!.on(event, handler);
        }
      });
    });

    _socket!.on('disconnect', (_) {
      debugPrint('Disconnected from socket server');
    });

    _socket!.on('connectError', (data) {
      debugPrint('Connection Error: $data');
      // Detect common auth error indicators
      if (data?.toString().toLowerCase().contains(
                'unauthorized',
              ) ==
              true ||
          data?.toString().toLowerCase().contains('auth') ==
              true) {
        onAuthError?.call();
      }
    });

    _socket!.on('error', (data) {
      debugPrint('Socket Error: $data');
      if (data?.toString().toLowerCase().contains(
                'unauthorized',
              ) ==
              true ||
          data?.toString().toLowerCase().contains('auth') ==
              true) {
        onAuthError?.call();
      }
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    // We keep handlers registered in case of reconnection
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  void on(String event, Function(dynamic) handler) {
    _handlers.putIfAbsent(event, () => []).add(handler);
    _socket?.on(event, handler);
  }

  void off(String event, [Function(dynamic)? handler]) {
    if (handler != null) {
      _handlers[event]?.remove(handler);
      _socket?.off(event, handler);
    } else {
      _handlers.remove(event);
      _socket?.off(event);
    }
  }
}

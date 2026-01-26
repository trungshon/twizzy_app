import 'package:flutter/foundation.dart';
import '../../services/socket_service/socket_service.dart';

class ChatViewModel extends ChangeNotifier {
  final SocketService _socketService = SocketService();
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  void connect(String token) {
    _socketService.connect(token);

    // Use .on('connect') for better compatibility
    _socketService.socket?.on('connect', (_) {
      _isConnected = true;
      notifyListeners();
    });

    _socketService.socket?.on('disconnect', (_) {
      _isConnected = false;
      notifyListeners();
    });
  }

  void disconnect() {
    _socketService.disconnect();
    _isConnected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }
}

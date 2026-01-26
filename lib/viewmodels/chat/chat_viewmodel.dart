import 'package:flutter/foundation.dart';
import '../../services/socket_service/socket_service.dart';
import '../../services/chat_service/chat_service.dart';
import '../../models/chat/chat_models.dart';

class ChatViewModel extends ChangeNotifier {
  final SocketService _socketService;
  final ChatService _chatService;

  bool _isConnected = false;
  List<ChatThread> _allConversations = [];
  List<ChatThread> _requestConversations = [];
  bool _isLoadingList = false;
  String? _lastUserId;

  ChatViewModel(this._socketService, this._chatService) {
    _initListeners();
  }

  bool get isConnected => _isConnected;
  List<ChatThread> get allConversations => _allConversations;
  List<ChatThread> get requestConversations =>
      _requestConversations;
  bool get isLoadingList => _isLoadingList;

  void _initListeners() {
    _socketService.on('connect', (_) {
      debugPrint('ChatViewModel: Connected');
      _isConnected = true;
      notifyListeners();
    });

    _socketService.on('disconnect', (_) {
      debugPrint('ChatViewModel: Disconnected');
      _isConnected = false;
      notifyListeners();
    });

    _socketService.on('receive_message', (data) {
      if (_lastUserId != null) {
        loadConversationsList(_lastUserId!);
      } else {
        notifyListeners();
      }
    });
  }

  Future<void> loadCurrentConversations() async {
    if (_lastUserId != null) {
      return loadConversationsList(_lastUserId!);
    }
  }

  Future<void> loadConversationsList(
    String currentUserId,
  ) async {
    _lastUserId = currentUserId;
    _isLoadingList = true;
    notifyListeners();

    try {
      final list = await _chatService.getConversationsList();

      _allConversations =
          list.where((t) {
            // Show in "All" if it's accepted OR if I am the sender
            return t.latestMessage.isAccepted ||
                t.latestMessage.senderId == currentUserId;
          }).toList();

      _requestConversations =
          list.where((t) {
            // Show in "Requests" if it's NOT accepted AND I am the receiver
            return !t.latestMessage.isAccepted &&
                t.latestMessage.receiverId == currentUserId;
          }).toList();
    } catch (e) {
      debugPrint('Error loading conversations: $e');
    } finally {
      _isLoadingList = false;
      notifyListeners();
    }
  }

  Future<void> acceptConversation(String senderId) async {
    try {
      await _chatService.acceptConversation(senderId);
      if (_lastUserId != null)
        await loadConversationsList(_lastUserId!);
    } catch (e) {
      debugPrint('Error accepting conversation: $e');
    }
  }

  Future<void> deleteConversation(String senderId) async {
    try {
      await _chatService.deleteConversation(senderId);
      if (_lastUserId != null)
        await loadConversationsList(_lastUserId!);
    } catch (e) {
      debugPrint('Error deleting conversation: $e');
    }
  }

  void sendMessage(
    String receiverId,
    String senderId,
    String content,
  ) {
    _socketService.emit('send_message', {
      'payload': {
        'receiver_id': receiverId,
        'sender_id': senderId,
        'content': content,
      },
    });
    // Optimistic update would be nice, but for now we wait for socket/API
  }

  void connect(String token) {
    _socketService.connect(token);
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

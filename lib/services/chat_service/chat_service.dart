import '../../models/chat/chat_models.dart';
import '../api/api_client.dart';

class ChatService {
  final ApiClient _apiClient;

  ChatService(this._apiClient);

  Future<List<ChatThread>> getConversationsList() async {
    final response = await _apiClient.get(
      '/conversations/list',
      includeAuth: true,
    );
    final List result = response['result'];
    return result
        .map((json) => ChatThread.fromJson(json))
        .toList();
  }

  Future<Map<String, dynamic>> getConversations({
    required String receiverId,
    int limit = 10,
    int page = 1,
  }) async {
    final response = await _apiClient.get(
      '/conversations/receivers/$receiverId?limit=$limit&page=$page',
      includeAuth: true,
    );
    return response['result'];
  }

  Future<void> acceptConversation(String senderId) async {
    await _apiClient.put(
      '/conversations/receivers/$senderId/accept',
      includeAuth: true,
    );
  }

  Future<void> deleteConversation(String senderId) async {
    await _apiClient.delete(
      '/conversations/receivers/$senderId/delete',
      includeAuth: true,
    );
  }

  Future<void> markAsRead(String senderId) async {
    await _apiClient.patch(
      '/conversations/receivers/$senderId/mark-as-read',
      includeAuth: true,
    );
  }
}

import '../config/api_config.dart';
import '../models/chat_message.dart';
import 'api_client.dart';

class ChatApiService {
  Future<List<ChatMessage>> getMessages(String bookingId) async {
    final response = await ApiClient.get(ApiConfig.bookingChat(bookingId));
    final data = response['data'];
    if (data['messages'] is List) {
      return (data['messages'] as List)
          .map((json) => ChatMessage.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    }
    return [];
  }

  Future<ChatMessage> sendMessage(String bookingId, String message) async {
    final response = await ApiClient.post(
      ApiConfig.bookingChat(bookingId),
      {'message': message},
    );
    final data = response['data'];
    return ChatMessage.fromJson(Map<String, dynamic>.from(data['message']));
  }
}

import '../config/api_config.dart';
import 'api_client.dart';

class SupportMessage {
  final String id;
  final String senderId;
  final String senderRole;
  final String text;
  final DateTime sentAt;

  SupportMessage({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.text,
    required this.sentAt,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: json['_id']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderRole: json['senderRole']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      sentAt: json['sentAt'] != null
          ? DateTime.tryParse(json['sentAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class SupportTicket {
  final String id;
  final String bookingId;
  final String issue;
  final String status;
  final List<SupportMessage> messages;

  SupportTicket({
    required this.id,
    required this.bookingId,
    required this.issue,
    required this.status,
    required this.messages,
  });

  bool get isClosed => status == 'closed';

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'];
    final messages = rawMessages is List
        ? rawMessages
              .map(
                (m) =>
                    SupportMessage.fromJson(Map<String, dynamic>.from(m as Map)),
              )
              .toList()
        : <SupportMessage>[];

    return SupportTicket(
      id: json['_id']?.toString() ?? '',
      bookingId: json['bookingId'] is Map
          ? (json['bookingId'] as Map)['_id']?.toString() ?? ''
          : json['bookingId']?.toString() ?? '',
      issue: json['issue']?.toString() ?? '',
      status: json['status']?.toString() ?? 'open',
      messages: messages,
    );
  }
}

class SupportApiService {
  Future<SupportTicket> createTicket(String bookingId, String issue) async {
    final response = await ApiClient.post(
      ApiConfig.createSupportTicket(bookingId),
      {'issue': issue},
    );
    return SupportTicket.fromJson(
      Map<String, dynamic>.from(response['data']['ticket'] as Map),
    );
  }

  Future<SupportTicket> getTicket(String bookingId) async {
    final response = await ApiClient.get(ApiConfig.getSupportTicket(bookingId));
    return SupportTicket.fromJson(
      Map<String, dynamic>.from(response['data']['ticket'] as Map),
    );
  }

  Future<SupportMessage> sendMessage(String ticketId, String text) async {
    final response = await ApiClient.post(
      ApiConfig.supportMessages(ticketId),
      {'text': text},
    );
    return SupportMessage.fromJson(
      Map<String, dynamic>.from(response['data']['message'] as Map),
    );
  }

  Future<List<SupportMessage>> getMessages(String ticketId) async {
    final response = await ApiClient.get(ApiConfig.supportMessages(ticketId));
    final data = response['data'];
    if (data['messages'] is List) {
      return (data['messages'] as List)
          .map(
            (m) => SupportMessage.fromJson(Map<String, dynamic>.from(m as Map)),
          )
          .toList();
    }
    return [];
  }
}

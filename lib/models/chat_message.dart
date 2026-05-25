class ChatMessage {
  final String id;
  final String bookingId;
  final String senderId;
  final String receiverId;
  final String message;
  final String createdAt;
  final Map<String, dynamic>? senderDetails;

  ChatMessage({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.createdAt,
    this.senderDetails,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'] ?? json['id'] ?? '',
      bookingId: json['bookingId'] is Map
          ? json['bookingId']['_id'] ?? ''
          : json['bookingId'] ?? '',
      senderId: json['senderId'] is Map
          ? json['senderId']['_id'] ?? ''
          : json['senderId'] ?? '',
      receiverId: json['receiverId'] is Map
          ? json['receiverId']['_id'] ?? ''
          : json['receiverId'] ?? '',
      message: json['message'] ?? '',
      createdAt: json['createdAt'] ?? '',
      senderDetails: json['senderId'] is Map ? json['senderId'] : null,
    );
  }
}

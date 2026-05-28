class MessageModel {
  final int id;
  final int adId;
  final int senderId;
  final int receiverId;
  final String message;
  final DateTime createdAt;
  final bool isMine;
  final String senderName;

  MessageModel({
    required this.id,
    required this.adId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.createdAt,
    required this.isMine,
    required this.senderName,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json, int currentUserId) {
    final created = DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now();
    return MessageModel(
      id: json['id'],
      adId: json['ad_id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      message: json['message'] ?? '',
      createdAt: created,
      isMine: json['sender_id'] == currentUserId,
      senderName: json['sender_name'] ?? 'Usuário',
    );
  }
}

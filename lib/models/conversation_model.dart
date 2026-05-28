class ConversationModel {
  final int adId;
  final String adTitle;
  final String? adSlug;
  final int otherUserId;
  final String otherUserName;
  final DateTime lastMessageAt;
  final int unreadCount;
  final String lastMessage;
  final String lastMessageTime;

  ConversationModel({
    required this.adId,
    required this.adTitle,
    this.adSlug,
    required this.otherUserId,
    required this.otherUserName,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.lastMessage,
    required this.lastMessageTime,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      adId: json['ad_id'],
      adTitle: json['ad_title'] ?? 'Anúncio',
      adSlug: json['ad_slug'],
      otherUserId: json['other_user_id'],
      otherUserName: json['other_user_name'] ?? 'Usuário',
      lastMessageAt: DateTime.tryParse(json['last_message_at'] ?? '') ?? DateTime.now(),
      unreadCount: int.tryParse(json['unread_count'].toString()) ?? 0,
      lastMessage: json['last_message'] ?? '',
      lastMessageTime: json['last_message_time'] ?? '',
    );
  }
}

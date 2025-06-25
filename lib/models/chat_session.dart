class ChatSession {
  final String userId;
  final String conversationId;
  final String userName;
  final String phone;
  final String? userProfile;

  ChatSession({
    required this.userId,
    required this.conversationId,
    required this.userName,
    required this.phone,
    this.userProfile,

  });
}

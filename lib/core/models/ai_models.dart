class AIMessage {
  final String text;
  final bool isUser;
  final String time;
  final String? imageUrl;

  AIMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.imageUrl,
  });
}
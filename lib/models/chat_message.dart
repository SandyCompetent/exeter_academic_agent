class ChatMessage {
  String text;
  final bool isUser;
  final DateTime timestamp;
  bool isThinking;
  List<String>? suggestions;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isThinking = false,
    this.suggestions,
  });
}

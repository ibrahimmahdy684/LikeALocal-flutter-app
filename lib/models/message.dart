class ChatMessage {
  String text;
  bool isAI;
  DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isAI,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

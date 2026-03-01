class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  final ToolRequest? toolRequest;

  Message({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.toolRequest,
  }) : timestamp = timestamp ?? DateTime.now();

  Message copyWith({
    String? text,
    bool? isUser,
    DateTime? timestamp,
    ToolRequest? toolRequest,
  }) {
    return Message(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      toolRequest: toolRequest ?? this.toolRequest,
    );
  }
}

class ToolRequest {
  final String toolName;
  final Map<String, dynamic> arguments;

  ToolRequest({required this.toolName, required this.arguments});
}

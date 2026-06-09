class Conversation {
  Conversation({
    required this.id,
    required this.type,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.documentId,
    this.messages = const [],
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      documentId: json['document_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      messages: (json['messages'] as List<dynamic>?)
              ?.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  final String id;
  final String type;
  final String title;
  final String? documentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;
}

class ChatMessage {
  ChatMessage({
    required this.role,
    required this.content,
    this.citations,
    this.isStreaming = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String,
      content: json['content'] as String,
      citations: json['citations'] as List<dynamic>?,
    );
  }

  final String role;
  final String content;
  final List<dynamic>? citations;
  final bool isStreaming;

  ChatMessage copyWith({String? content, bool? isStreaming, List<dynamic>? citations}) {
    return ChatMessage(
      role: role,
      content: content ?? this.content,
      citations: citations ?? this.citations,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

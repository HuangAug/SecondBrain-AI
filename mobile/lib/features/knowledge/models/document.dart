class KnowledgeDocument {
  KnowledgeDocument({
    required this.id,
    required this.filename,
    required this.fileType,
    required this.status,
    required this.chunkCount,
    required this.createdAt,
    this.errorMessage,
  });

  factory KnowledgeDocument.fromJson(Map<String, dynamic> json) {
    return KnowledgeDocument(
      id: json['id'] as String,
      filename: json['filename'] as String,
      fileType: json['file_type'] as String,
      status: json['status'] as String,
      chunkCount: json['chunk_count'] as int? ?? 0,
      errorMessage: json['error_message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String filename;
  final String fileType;
  final String status;
  final int chunkCount;
  final String? errorMessage;
  final DateTime createdAt;

  String get statusLabel {
    switch (status) {
      case 'pending':
        return '等待处理';
      case 'processing':
        return '处理中';
      case 'ready':
        return '可用';
      case 'failed':
        return '处理失败';
      default:
        return status;
    }
  }
}

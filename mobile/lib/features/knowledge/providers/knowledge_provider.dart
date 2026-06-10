import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/document.dart';

final documentsProvider = FutureProvider<List<KnowledgeDocument>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final resp = await api.dio.get('/documents');
  return (resp.data as List)
      .map((e) => KnowledgeDocument.fromJson(e as Map<String, dynamic>))
      .toList();
});

class KnowledgeActions {
  KnowledgeActions(this._api);

  final ApiClient _api;

  Future<void> uploadFile() async {
    const typeGroup = XTypeGroup(
      label: 'documents',
      extensions: ['pdf', 'txt', 'md', 'docx', 'doc'],
    );
    final file = await openFile(
      acceptedTypeGroups: const [typeGroup],
    );
    if (file == null) {
      throw Exception('未选择文件');
    }
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: file.name),
    });

    await _api.dio.post('/documents/upload', data: formData);
  }

  Future<void> deleteDocument(String documentId) async {
    await _api.dio.delete('/documents/$documentId');
  }

  Future<void> deleteDocuments(List<String> documentIds) async {
    await _api.dio.post('/documents/bulk-delete', data: {
      'ids': documentIds,
    });
  }

  Future<String> createRagConversation(String documentId,
      {String? title}) async {
    final resp = await _api.dio.post('/conversations', data: {
      'type': 'rag',
      'title': title ?? '文档问答',
      'document_id': documentId,
    });
    return (resp.data as Map<String, dynamic>)['id'] as String;
  }

  Future<String> createKnowledgeBaseConversation({String? title}) async {
    final resp = await _api.dio.post('/conversations', data: {
      'type': 'rag',
      'title': title ?? '我的知识库问答',
    });
    return (resp.data as Map<String, dynamic>)['id'] as String;
  }
}

final knowledgeActionsProvider = Provider<KnowledgeActions>((ref) {
  return KnowledgeActions(ref.watch(apiClientProvider));
});

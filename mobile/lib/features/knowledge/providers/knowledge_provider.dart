import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/document.dart';

final documentsProvider = FutureProvider<List<KnowledgeDocument>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final resp = await api.dio.get('/documents');
  return (resp.data as List).map((e) => KnowledgeDocument.fromJson(e as Map<String, dynamic>)).toList();
});

class KnowledgeActions {
  KnowledgeActions(this._api);

  final ApiClient _api;

  Future<void> uploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'md'],
    );
    if (result == null || result.files.isEmpty) {
      throw Exception('未选择文件');
    }

    final file = result.files.first;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path!, filename: file.name),
    });

    await _api.dio.post('/documents/upload', data: formData);
  }

  Future<String> createRagConversation(String documentId, {String? title}) async {
    final resp = await _api.dio.post('/conversations', data: {
      'type': 'rag',
      'title': title ?? '文档问答',
      'document_id': documentId,
    });
    return (resp.data as Map<String, dynamic>)['id'] as String;
  }
}

final knowledgeActionsProvider = Provider<KnowledgeActions>((ref) {
  return KnowledgeActions(ref.watch(apiClientProvider));
});

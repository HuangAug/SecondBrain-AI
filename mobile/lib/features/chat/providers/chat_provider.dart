import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/conversation.dart';

final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final resp = await api.dio.get('/conversations');
  return (resp.data as List).map((e) => Conversation.fromJson(e as Map<String, dynamic>)).toList();
});

final conversationDetailProvider = FutureProvider.family<Conversation, String>((ref, id) async {
  final api = ref.watch(apiClientProvider);
  final resp = await api.dio.get('/conversations/$id');
  return Conversation.fromJson(resp.data as Map<String, dynamic>);
});

class ChatStreamNotifier extends StateNotifier<List<ChatMessage>> {
  ChatStreamNotifier(this._api) : super([]);

  final ApiClient _api;
  String? _conversationId;

  void setMessages(List<ChatMessage> messages) => state = messages;

  String? get conversationId => _conversationId;

  Future<void> sendMessage(String text, {String? conversationId}) async {
    state = [...state, ChatMessage(role: 'user', content: text)];
    state = [...state, ChatMessage(role: 'assistant', content: '', isStreaming: true)];

    try {
      final resp = await _api.dio.post(
        '/chat/stream',
        data: {
          'message': text,
          if (conversationId != null) 'conversation_id': conversationId,
        },
        options: Options(responseType: ResponseType.stream),
      );

      final stream = resp.data.stream as ResponseBody;
      final buffer = StringBuffer();

      await for (final chunk in stream.stream) {
        final text = utf8.decode(chunk);
        for (final line in text.split('\n')) {
          if (!line.startsWith('data: ')) continue;
          final jsonStr = line.substring(6).trim();
          if (jsonStr.isEmpty) continue;
          final data = json.decode(jsonStr) as Map<String, dynamic>;
          if (data['content'] != null && (data['content'] as String).isNotEmpty) {
            buffer.write(data['content']);
            final updated = state.last.copyWith(content: buffer.toString(), isStreaming: true);
            state = [...state.sublist(0, state.length - 1), updated];
          }
          if (data['done'] == true) {
            _conversationId = data['conversation_id'] as String?;
            final citations = data['citations'] as List<dynamic>?;
            final finalMsg = state.last.copyWith(isStreaming: false, citations: citations);
            state = [...state.sublist(0, state.length - 1), finalMsg];
          }
        }
      }
    } catch (e) {
      final errorMsg = state.last.copyWith(content: '发送失败：$e', isStreaming: false);
      state = [...state.sublist(0, state.length - 1), errorMsg];
    }
  }
}

final chatStreamProvider = StateNotifierProvider<ChatStreamNotifier, List<ChatMessage>>((ref) {
  return ChatStreamNotifier(ref.watch(apiClientProvider));
});

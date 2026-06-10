import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/navigation_helpers.dart';
import '../models/conversation.dart';
import '../providers/chat_provider.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  const ChatDetailScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _controller = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.conversationId == 'new';
    final messages = ref.watch(chatStreamProvider);

    if (!isNew && !_initialized) {
      final detail =
          ref.watch(conversationDetailProvider(widget.conversationId));
      detail.whenData((conv) {
        if (!_initialized) {
          _initialized = true;
          ref.read(chatStreamProvider.notifier).setMessages(
                conv.messages
                    .map((m) => ChatMessage(
                        role: m.role,
                        content: m.content,
                        citations: m.citations))
                    .toList(),
              );
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? '新对话' : '对话详情'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => goBackOrHome(context, fallback: '/chat'),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg.role == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isUser)
                          Text(msg.content)
                        else
                          MarkdownBody(
                              data: msg.content.isEmpty && msg.isStreaming
                                  ? '...'
                                  : msg.content),
                        if (msg.isStreaming)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        if (msg.citations != null && msg.citations!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '引用：${msg.citations!.map((c) => c['source']).join(', ')}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: '输入你的问题...'),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _send,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    final convId =
        widget.conversationId == 'new' ? null : widget.conversationId;
    ref
        .read(chatStreamProvider.notifier)
        .sendMessage(text, conversationId: convId);
  }
}

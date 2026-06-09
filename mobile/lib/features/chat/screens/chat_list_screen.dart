import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/chat_provider.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('对话')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/chat/new'),
        child: const Icon(Icons.add),
      ),
      body: conversations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (list) {
          final chatConvs = list.where((c) => c.type == 'chat' || c.type == 'rag').toList();
          if (chatConvs.isEmpty) {
            return const Center(child: Text('暂无对话，点击 + 开始'));
          }
          return ListView.builder(
            itemCount: chatConvs.length,
            itemBuilder: (context, index) {
              final conv = chatConvs[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Icon(conv.type == 'rag' ? Icons.description : Icons.chat),
                ),
                title: Text(conv.title),
                subtitle: Text(DateFormat('MM-dd HH:mm').format(conv.updatedAt)),
                onTap: () => context.push('/chat/${conv.id}'),
              );
            },
          );
        },
      ),
    );
  }
}

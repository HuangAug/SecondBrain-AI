import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/chat_provider.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final Set<String> _selectedIds = {};

  bool get _selecting => _selectedIds.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_selecting ? '已选择 ${_selectedIds.length} 个对话' : '对话'),
        leading: _selecting
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(_selectedIds.clear),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/home'),
              ),
        actions: [
          if (_selecting)
            IconButton(
              tooltip: '删除所选对话',
              onPressed: () => _confirmDeleteSelected(),
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/chat/new'),
        child: const Icon(Icons.add),
      ),
      body: conversations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (list) {
          final chatConvs =
              list.where((c) => c.type == 'chat' || c.type == 'rag').toList();
          if (chatConvs.isEmpty) {
            return const Center(child: Text('暂无对话，点击 + 开始'));
          }
          return ListView.builder(
            itemCount: chatConvs.length,
            itemBuilder: (context, index) {
              final conv = chatConvs[index];
              final selected = _selectedIds.contains(conv.id);
              return ListTile(
                leading: CircleAvatar(
                  child: selected
                      ? const Icon(Icons.check)
                      : Icon(
                          conv.type == 'rag' ? Icons.description : Icons.chat),
                ),
                title: Text(conv.title),
                subtitle:
                    Text(DateFormat('MM-dd HH:mm').format(conv.updatedAt)),
                trailing: _selecting
                    ? Checkbox(
                        value: selected,
                        onChanged: (_) => _toggleSelection(conv.id),
                      )
                    : PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'delete') {
                            await _confirmDelete([conv.id]);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('删除对话'),
                          ),
                        ],
                      ),
                selected: selected,
                onLongPress: () => _toggleSelection(conv.id),
                onTap: () {
                  if (_selecting) {
                    _toggleSelection(conv.id);
                  } else {
                    context.push('/chat/${conv.id}');
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  void _toggleSelection(String conversationId) {
    setState(() {
      if (_selectedIds.contains(conversationId)) {
        _selectedIds.remove(conversationId);
      } else {
        _selectedIds.add(conversationId);
      }
    });
  }

  Future<void> _confirmDeleteSelected() async {
    await _confirmDelete(_selectedIds.toList());
  }

  Future<void> _confirmDelete(List<String> conversationIds) async {
    if (conversationIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(conversationIds.length == 1 ? '删除对话？' : '删除所选对话？'),
        content: Text(
          conversationIds.length == 1
              ? '删除后该对话和消息记录都会被移除，无法恢复。'
              : '将删除 ${conversationIds.length} 个对话和对应消息记录，无法恢复。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (conversationIds.length == 1) {
        await ref
            .read(conversationActionsProvider)
            .deleteConversation(conversationIds.first);
      } else {
        await ref
            .read(conversationActionsProvider)
            .deleteConversations(conversationIds);
      }
      setState(() => _selectedIds.removeAll(conversationIds));
      ref.invalidate(conversationsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已删除 ${conversationIds.length} 个对话')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('删除失败：$e')));
      }
    }
  }
}

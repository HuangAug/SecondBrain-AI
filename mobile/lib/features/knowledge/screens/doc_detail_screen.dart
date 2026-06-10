import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/navigation_helpers.dart';
import '../../chat/providers/chat_provider.dart';
import '../../chat/screens/chat_detail_screen.dart';
import '../models/document.dart';
import '../providers/knowledge_provider.dart';

class DocDetailScreen extends ConsumerStatefulWidget {
  const DocDetailScreen({super.key, required this.documentId});

  final String documentId;

  @override
  ConsumerState<DocDetailScreen> createState() => _DocDetailScreenState();
}

class _DocDetailScreenState extends ConsumerState<DocDetailScreen> {
  String? _conversationId;
  bool _creating = false;

  Future<void> _startChat() async {
    setState(() => _creating = true);
    try {
      final convId = await ref
          .read(knowledgeActionsProvider)
          .createRagConversation(widget.documentId);
      setState(() => _conversationId = convId);
      ref.read(chatStreamProvider.notifier).setMessages([]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('创建对话失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final documents = ref.watch(documentsProvider);
    KnowledgeDocument? doc;
    final docList = documents.valueOrNull;
    if (docList != null) {
      for (final d in docList) {
        if (d.id == widget.documentId) {
          doc = d;
          break;
        }
      }
    }

    if (_conversationId != null) {
      return ChatDetailScreen(conversationId: _conversationId!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(doc?.filename ?? '文档详情'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => goBackOrHome(context, fallback: '/knowledge'),
        ),
        actions: [
          IconButton(
            tooltip: '删除文档',
            onPressed: () => _confirmDeleteDocument(),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (doc != null) ...[
              Text('状态：${doc.statusLabel}',
                  style: Theme.of(context).textTheme.titleMedium),
              if (doc.chunkCount > 0) Text('已索引 ${doc.chunkCount} 个片段'),
              if (doc.errorMessage != null)
                Text('错误：${doc.errorMessage}',
                    style: const TextStyle(color: Colors.red)),
            ],
            const Spacer(),
            FilledButton.icon(
              onPressed: _creating ? null : _startChat,
              icon: _creating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.chat),
              label: const Text('基于此文档提问'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteDocument() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除知识库文档？'),
        content: const Text('删除后该文档、索引片段和本地文件都会被移除，无法恢复。'),
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
      await ref
          .read(knowledgeActionsProvider)
          .deleteDocument(widget.documentId);
      ref.invalidate(documentsProvider);
      if (mounted) {
        context.go('/knowledge');
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('文档已删除')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('删除失败：$e')));
      }
    }
  }
}

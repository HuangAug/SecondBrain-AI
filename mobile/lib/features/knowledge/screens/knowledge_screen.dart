import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../chat/providers/chat_provider.dart';
import '../providers/knowledge_provider.dart';

class KnowledgeScreen extends ConsumerStatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  ConsumerState<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends ConsumerState<KnowledgeScreen> {
  bool _uploading = false;
  bool _creatingChat = false;

  Future<void> _upload() async {
    setState(() => _uploading = true);
    try {
      await ref.read(knowledgeActionsProvider).uploadFile();
      ref.invalidate(documentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('上传成功，正在后台处理')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('上传失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _startKnowledgeChat() async {
    setState(() => _creatingChat = true);
    try {
      final convId = await ref
          .read(knowledgeActionsProvider)
          .createKnowledgeBaseConversation();
      ref.read(chatStreamProvider.notifier).setMessages([]);
      if (mounted) {
        context.push('/chat/$convId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('创建知识库对话失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _creatingChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final documents = ref.watch(documentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('知识库'),
        actions: [
          IconButton(
            tooltip: '问我的知识库',
            onPressed: _creatingChat ? null : _startKnowledgeChat,
            icon: _creatingChat
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.psychology),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploading ? null : _upload,
        child: _uploading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.upload_file),
      ),
      body: documents.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('上传 PDF/TXT/Markdown/Word 开始构建知识库'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _creatingChat ? null : _startKnowledgeChat,
                    icon: const Icon(Icons.psychology),
                    label: const Text('问我的知识库'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: list.length + 1,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Card(
                  child: ListTile(
                    leading: _creatingChat
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.psychology),
                    title: const Text('问我的知识库'),
                    subtitle: const Text('从当前账号所有已处理文档中检索答案'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _creatingChat ? null : _startKnowledgeChat,
                  ),
                );
              }
              final doc = list[index - 1];
              return Card(
                child: ListTile(
                  leading: Icon(_iconForType(doc.fileType)),
                  title: Text(doc.filename,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                      '${doc.statusLabel} · ${DateFormat('MM-dd').format(doc.createdAt)}'),
                  trailing: doc.status == 'ready'
                      ? const Icon(Icons.chevron_right)
                      : null,
                  onTap: doc.status == 'ready'
                      ? () => context.push('/documents/${doc.id}')
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'md':
      case 'markdown':
        return Icons.article;
      case 'docx':
      case 'doc':
        return Icons.description;
      default:
        return Icons.description;
    }
  }
}

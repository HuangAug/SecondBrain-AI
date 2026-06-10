import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/navigation_helpers.dart';
import '../providers/plan_provider.dart';

class PlanListScreen extends ConsumerWidget {
  const PlanListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(plansProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('学习计划'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => goBackOrHome(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/plans/new'),
        child: const Icon(Icons.add),
      ),
      body: plans.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('暂无学习计划'));
          }
          return ListView.builder(
            itemCount: list.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final plan = list[index];
              final completed = plan.tasks.where((t) => t.completed).length;
              final total = plan.tasks.length;
              return Card(
                child: ListTile(
                  title: Text(plan.goal,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle:
                      Text('$completed / $total 任务完成 · ${plan.durationDays} 天'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'delete') {
                        await _confirmDelete(context, ref, plan.id);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('删除计划'),
                      ),
                    ],
                  ),
                  onTap: () => context.push('/plans/${plan.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String planId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除学习计划？'),
        content: const Text('删除后该计划和所有任务都会被移除，无法恢复。'),
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
      await ref.read(planActionsProvider).deletePlan(planId);
      ref.invalidate(plansProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('学习计划已删除')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('删除失败：$e')));
      }
    }
  }
}

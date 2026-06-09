import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/plan_provider.dart';

class PlanListScreen extends ConsumerWidget {
  const PlanListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(plansProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('学习计划')),
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
                  title: Text(plan.goal, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text('$completed / $total 任务完成 · ${plan.durationDays} 天'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/plans/${plan.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

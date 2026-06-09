import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/plan_provider.dart';

class PlanDetailScreen extends ConsumerWidget {
  const PlanDetailScreen({super.key, required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(planDetailProvider(planId));
    final progress = ref.watch(planProgressProvider(planId));

    return Scaffold(
      appBar: AppBar(title: const Text('计划详情')),
      body: plan.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (p) {
          final completed = p.tasks.where((t) => t.completed).length;
          final percent = p.tasks.isEmpty ? 0.0 : completed / p.tasks.length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(p.goal, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: percent,
                      strokeWidth: 8,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${(percent * 100).round()}% 完成'),
                      Text('$completed / ${p.tasks.length} 任务'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              progress.when(
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
                data: (prog) {
                  if (prog.todayTasks.isEmpty) return const SizedBox();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('今日任务', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ...prog.todayTasks.map((t) => _TaskTile(planId: planId, task: t)),
                      const Divider(height: 32),
                    ],
                  );
                },
              ),
              Text('全部任务', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...p.tasks.map((t) => _TaskTile(planId: planId, task: t)),
            ],
          );
        },
      ),
    );
  }
}

class _TaskTile extends ConsumerWidget {
  const _TaskTile({required this.planId, required this.task});

  final String planId;
  final dynamic task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CheckboxListTile(
      value: task.completed,
      title: Text('第 ${task.dayIndex} 天：${task.title}'),
      subtitle: task.description.isNotEmpty ? Text(task.description) : null,
      onChanged: (v) async {
        await ref.read(planActionsProvider).toggleTask(task.id, v ?? false);
        ref.invalidate(planDetailProvider(planId));
        ref.invalidate(planProgressProvider(planId));
        ref.invalidate(plansProvider);
      },
    );
  }
}

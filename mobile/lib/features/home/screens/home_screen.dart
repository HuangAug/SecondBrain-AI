import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../study_plan/providers/plan_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final plans = ref.watch(plansProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('你好，${auth.nickname ?? "学习者"}！', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('今天也要加油学习哦', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              onPressed: () => context.push('/chat/new'),
              icon: const Icon(Icons.chat),
              label: const Text('开始 AI 辅导'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/plans/new'),
              icon: const Icon(Icons.calendar_month),
              label: const Text('创建学习计划'),
            ),
            const SizedBox(height: 24),
            Text('今日任务', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: plans.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('加载失败：$e')),
                data: (list) {
                  if (list.isEmpty) {
                    return const Center(child: Text('暂无学习计划，创建一个吧'));
                  }
                  final activePlan = list.first;
                  return FutureBuilder(
                    future: ref.read(planProgressProvider(activePlan.id).future),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final progress = snapshot.data!;
                      if (progress.todayTasks.isEmpty) {
                        return Center(
                          child: Text('计划「${activePlan.goal}」今日无任务或已完成'),
                        );
                      }
                      return ListView(
                        children: progress.todayTasks
                            .map((t) => Card(
                                  child: ListTile(
                                    leading: Icon(
                                      t.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                                      color: t.completed ? Colors.green : null,
                                    ),
                                    title: Text(t.title),
                                    subtitle: Text(t.description),
                                  ),
                                ))
                            .toList(),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/navigation_helpers.dart';
import '../../../core/router/app_router.dart';
import '../providers/plan_provider.dart';

class PlanWizardScreen extends ConsumerStatefulWidget {
  const PlanWizardScreen({super.key});

  @override
  ConsumerState<PlanWizardScreen> createState() => _PlanWizardScreenState();
}

class _PlanWizardScreenState extends ConsumerState<PlanWizardScreen> {
  final _goalController = TextEditingController();
  String _level = 'beginner';
  int _days = 7;
  bool _loading = false;

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_goalController.text.trim().isEmpty) return;
    setState(() => _loading = true);

    final goal = _goalController.text.trim();
    final level = _level;
    final days = _days;
    final container = ProviderScope.containerOf(context, listen: false);
    final actions = container.read(planActionsProvider);

    context.go('/home');

    try {
      final plan = await actions.createPlan(
        goal: goal,
        level: level,
        durationDays: days,
      );
      container.invalidate(plansProvider);
      if (rootNavigatorKey.currentContext != null) {
        await showDialog<void>(
          context: rootNavigatorKey.currentContext!,
          builder: (context) => AlertDialog(
            title: const Text('学习计划已生成'),
            content: Text('「${plan.goal}」的学习计划已创建完成。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('稍后查看'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  rootNavigatorKey.currentContext?.go('/plans/${plan.id}');
                },
                child: const Text('前往查看'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (rootNavigatorKey.currentContext != null) {
        await showDialog<void>(
          context: rootNavigatorKey.currentContext!,
          builder: (context) => AlertDialog(
            title: const Text('学习计划生成失败'),
            content: Text('生成失败：$e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('知道了'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('创建学习计划'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => goBackOrHome(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _goalController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '学习目标',
                hintText: '例如：掌握 Python 数据分析基础',
              ),
            ),
            const SizedBox(height: 24),
            Text('当前水平', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'beginner', label: Text('入门')),
                ButtonSegment(value: 'intermediate', label: Text('进阶')),
                ButtonSegment(value: 'advanced', label: Text('高级')),
              ],
              selected: {_level},
              onSelectionChanged: (s) => setState(() => _level = s.first),
            ),
            const SizedBox(height: 24),
            Text('计划天数：$_days 天',
                style: Theme.of(context).textTheme.titleSmall),
            Slider(
              value: _days.toDouble(),
              min: 3,
              max: 30,
              divisions: 27,
              label: '$_days 天',
              onChanged: (v) => setState(() => _days = v.round()),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _loading ? null : _generate,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('AI 生成计划'),
            ),
          ],
        ),
      ),
    );
  }
}

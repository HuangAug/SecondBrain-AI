import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    try {
      final plan = await ref.read(planActionsProvider).createPlan(
            goal: _goalController.text.trim(),
            level: _level,
            durationDays: _days,
          );
      ref.invalidate(plansProvider);
      if (mounted) context.go('/plans/${plan.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('生成失败：$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('创建学习计划')),
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
            Text('计划天数：$_days 天', style: Theme.of(context).textTheme.titleSmall),
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
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('AI 生成计划'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/study_plan.dart';

final plansProvider = FutureProvider<List<StudyPlan>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final resp = await api.dio.get('/plans');
  return (resp.data as List).map((e) => StudyPlan.fromJson(e as Map<String, dynamic>)).toList();
});

final planDetailProvider = FutureProvider.family<StudyPlan, String>((ref, id) async {
  final api = ref.watch(apiClientProvider);
  final resp = await api.dio.get('/plans/$id');
  return StudyPlan.fromJson(resp.data as Map<String, dynamic>);
});

final planProgressProvider = FutureProvider.family<PlanProgress, String>((ref, id) async {
  final api = ref.watch(apiClientProvider);
  final resp = await api.dio.get('/plans/$id/progress');
  return PlanProgress.fromJson(resp.data as Map<String, dynamic>);
});

class PlanActions {
  PlanActions(this._api);

  final ApiClient _api;

  Future<StudyPlan> createPlan({required String goal, required String level, required int durationDays}) async {
    final resp = await _api.dio.post('/plans', data: {
      'goal': goal,
      'level': level,
      'duration_days': durationDays,
    });
    return StudyPlan.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> toggleTask(String taskId, bool completed) async {
    await _api.dio.patch('/plans/tasks/$taskId', data: {'completed': completed});
  }
}

final planActionsProvider = Provider<PlanActions>((ref) {
  return PlanActions(ref.watch(apiClientProvider));
});

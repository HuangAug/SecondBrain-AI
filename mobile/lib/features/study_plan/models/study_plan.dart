class StudyPlan {
  StudyPlan({
    required this.id,
    required this.goal,
    required this.level,
    required this.durationDays,
    required this.status,
    required this.createdAt,
    this.tasks = const [],
  });

  factory StudyPlan.fromJson(Map<String, dynamic> json) {
    return StudyPlan(
      id: json['id'] as String,
      goal: json['goal'] as String,
      level: json['level'] as String,
      durationDays: json['duration_days'] as int,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      tasks: (json['tasks'] as List<dynamic>?)
              ?.map((t) => PlanTask.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  final String id;
  final String goal;
  final String level;
  final int durationDays;
  final String status;
  final DateTime createdAt;
  final List<PlanTask> tasks;
}

class PlanTask {
  PlanTask({
    required this.id,
    required this.dayIndex,
    required this.title,
    required this.description,
    required this.completed,
    this.completedAt,
  });

  factory PlanTask.fromJson(Map<String, dynamic> json) {
    return PlanTask(
      id: json['id'] as String,
      dayIndex: json['day_index'] as int,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
    );
  }

  final String id;
  final int dayIndex;
  final String title;
  final String description;
  final bool completed;
  final DateTime? completedAt;
}

class PlanProgress {
  PlanProgress({
    required this.planId,
    required this.totalTasks,
    required this.completedTasks,
    required this.progressPercent,
    this.todayTasks = const [],
  });

  factory PlanProgress.fromJson(Map<String, dynamic> json) {
    return PlanProgress(
      planId: json['plan_id'] as String,
      totalTasks: json['total_tasks'] as int,
      completedTasks: json['completed_tasks'] as int,
      progressPercent: (json['progress_percent'] as num).toDouble(),
      todayTasks: (json['today_tasks'] as List<dynamic>?)
              ?.map((t) => PlanTask.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  final String planId;
  final int totalTasks;
  final int completedTasks;
  final double progressPercent;
  final List<PlanTask> todayTasks;
}

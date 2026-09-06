class RecurringTask {
  final String id;
  final String title;
  final int durationMinutes;
  final int priority;
  final String category;
  final String frequency;
  final int? recurrenceWeekday;
  final int? lockedStartMinutes;
  final DateTime createdAt;

  const RecurringTask({
    required this.id,
    required this.title,
    required this.durationMinutes,
    required this.priority,
    required this.category,
    required this.frequency,
    this.recurrenceWeekday,
    this.lockedStartMinutes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'durationMinutes': durationMinutes,
        'priority': priority,
        'category': category,
        'frequency': frequency,
        'recurrenceWeekday': recurrenceWeekday,
        'lockedStartMinutes': lockedStartMinutes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory RecurringTask.fromMap(Map<String, dynamic> map) {
    return RecurringTask(
      id: map['id'] as String,
      title: map['title'] as String,
      durationMinutes: map['durationMinutes'] as int,
      priority: map['priority'] as int,
      category: map['category'] as String,
      frequency: map['frequency'] as String,
      recurrenceWeekday: map['recurrenceWeekday'] as int?,
      lockedStartMinutes: map['lockedStartMinutes'] as int?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

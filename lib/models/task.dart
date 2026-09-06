class Task {
  final int? id;
  final String title;
  final int durationMinutes;
  final int priority; // 9 = highest, 1 = lowest
  final String category; // work, school, personal, leisure
  final DateTime? lockedStartTime; // optional fixed start time
  final String status; // scheduled, complete, missed, unscheduled
  final int? dependsOnTaskId; // prerequisite task ID
  final bool isFlexible; // whether task can be moved
  final DateTime createdAt;
  final DateTime? scheduledStartTime; // when task is scheduled to start
  final DateTime? completedAt;

  Task({
    this.id,
    required this.title,
    required this.durationMinutes,
    required this.priority,
    required this.category,
    this.lockedStartTime,
    this.status = 'unscheduled',
    this.dependsOnTaskId,
    this.isFlexible = true,
    required this.createdAt,
    this.scheduledStartTime,
    this.completedAt,
  });

  // Convert Task to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'durationMinutes': durationMinutes,
      'priority': priority,
      'category': category,
      'lockedStartTime': lockedStartTime?.toIso8601String(),
      'status': status,
      'dependsOnTaskId': dependsOnTaskId,
      'isFlexible': isFlexible ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'scheduledStartTime': scheduledStartTime?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  // Create Task from Map
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      durationMinutes: map['durationMinutes'],
      priority: map['priority'],
      category: map['category'],
      lockedStartTime: map['lockedStartTime'] != null
          ? DateTime.parse(map['lockedStartTime'])
          : null,
      status: map['status'],
      dependsOnTaskId: map['dependsOnTaskId'],
      isFlexible: map['isFlexible'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      scheduledStartTime: map['scheduledStartTime'] != null
          ? DateTime.parse(map['scheduledStartTime'])
          : null,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
    );
  }

  // Copy with method for updates
  Task copyWith({
    int? id,
    String? title,
    int? durationMinutes,
    int? priority,
    String? category,
    DateTime? lockedStartTime,
    String? status,
    int? dependsOnTaskId,
    bool? isFlexible,
    DateTime? createdAt,
    DateTime? scheduledStartTime,
    DateTime? completedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      lockedStartTime: lockedStartTime ?? this.lockedStartTime,
      status: status ?? this.status,
      dependsOnTaskId: dependsOnTaskId ?? this.dependsOnTaskId,
      isFlexible: isFlexible ?? this.isFlexible,
      createdAt: createdAt ?? this.createdAt,
      scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  DateTime get endTime {
    if (scheduledStartTime == null) {
      throw StateError('Task has no scheduled start time');
    }
    return scheduledStartTime!.add(Duration(minutes: durationMinutes));
  }
}

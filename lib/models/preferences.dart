class Preferences {
  final int? id;
  final bool addBufferBetweenTasks; // 5-minute buffer
  final String overflowHandling; // 'push_next_day', 'unscheduled_section', 'prompt'
  final String defaultTaskStartDay; // 'today', 'tomorrow', 'custom'
  final String defaultCategory; // default category for new tasks
  final bool use24HourFormat;
  final String defaultViewMode; // 'day', 'week'
  final DateTime updatedAt;

  Preferences({
    this.id,
    this.addBufferBetweenTasks = false,
    this.overflowHandling = 'prompt',
    this.defaultTaskStartDay = 'tomorrow',
    this.defaultCategory = 'personal',
    this.use24HourFormat = true,
    this.defaultViewMode = 'day',
    required this.updatedAt,
  });

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'addBufferBetweenTasks': addBufferBetweenTasks ? 1 : 0,
      'overflowHandling': overflowHandling,
      'defaultTaskStartDay': defaultTaskStartDay,
      'defaultCategory': defaultCategory,
      'use24HourFormat': use24HourFormat ? 1 : 0,
      'defaultViewMode': defaultViewMode,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from Map
  factory Preferences.fromMap(Map<String, dynamic> map) {
    return Preferences(
      id: map['id'],
      addBufferBetweenTasks: map['addBufferBetweenTasks'] == 1,
      overflowHandling: map['overflowHandling'],
      defaultTaskStartDay: map['defaultTaskStartDay'],
      defaultCategory: map['defaultCategory'],
      use24HourFormat: map['use24HourFormat'] == 1,
      defaultViewMode: map['defaultViewMode'],
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // Copy with method
  Preferences copyWith({
    int? id,
    bool? addBufferBetweenTasks,
    String? overflowHandling,
    String? defaultTaskStartDay,
    String? defaultCategory,
    bool? use24HourFormat,
    String? defaultViewMode,
    DateTime? updatedAt,
  }) {
    return Preferences(
      id: id ?? this.id,
      addBufferBetweenTasks: addBufferBetweenTasks ?? this.addBufferBetweenTasks,
      overflowHandling: overflowHandling ?? this.overflowHandling,
      defaultTaskStartDay: defaultTaskStartDay ?? this.defaultTaskStartDay,
      defaultCategory: defaultCategory ?? this.defaultCategory,
      use24HourFormat: use24HourFormat ?? this.use24HourFormat,
      defaultViewMode: defaultViewMode ?? this.defaultViewMode,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Default preferences
  static Preferences defaultPreferences() {
    return Preferences(
      updatedAt: DateTime.now(),
    );
  }
}

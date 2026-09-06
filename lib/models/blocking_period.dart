class BlockingPeriod {
  final int? id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final bool isRecurring;
  final String? recurrencePattern; // daily, weekly, weekdays, weekends
  final DateTime createdAt;

  BlockingPeriod({
    this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.isRecurring = false,
    this.recurrencePattern,
    required this.createdAt,
  });

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'isRecurring': isRecurring ? 1 : 0,
      'recurrencePattern': recurrencePattern,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from Map
  factory BlockingPeriod.fromMap(Map<String, dynamic> map) {
    return BlockingPeriod(
      id: map['id'],
      title: map['title'],
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      isRecurring: map['isRecurring'] == 1,
      recurrencePattern: map['recurrencePattern'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  // Copy with method
  BlockingPeriod copyWith({
    int? id,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    bool? isRecurring,
    String? recurrencePattern,
    DateTime? createdAt,
  }) {
    return BlockingPeriod(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Check if a given DateTime falls within this blocking period
  bool blocksTime(DateTime time, {DateTime? forDate}) {
    if (!isRecurring) {
      return time.isAfter(startTime) && time.isBefore(endTime) ||
          time.isAtSameMomentAs(startTime);
    }

    // For recurring blocks, check if time falls within the pattern
    if (forDate != null && recurrencePattern != null) {
      switch (recurrencePattern) {
        case 'daily':
          return _isWithinTimeRange(time, forDate);
        case 'weekdays':
          if (forDate.weekday >= 1 && forDate.weekday <= 5) {
            return _isWithinTimeRange(time, forDate);
          }
          return false;
        case 'weekends':
          if (forDate.weekday == 6 || forDate.weekday == 7) {
            return _isWithinTimeRange(time, forDate);
          }
          return false;
        case 'weekly':
          if (forDate.weekday == startTime.weekday) {
            return _isWithinTimeRange(time, forDate);
          }
          return false;
        default:
          return false;
      }
    }

    return false;
  }

  bool _isWithinTimeRange(DateTime time, DateTime forDate) {
    // Create DateTime objects for comparison with same date
    final checkStart = DateTime(
      forDate.year,
      forDate.month,
      forDate.day,
      startTime.hour,
      startTime.minute,
    );
    final checkEnd = DateTime(
      forDate.year,
      forDate.month,
      forDate.day,
      endTime.hour,
      endTime.minute,
    );

    return (time.isAfter(checkStart) || time.isAtSameMomentAs(checkStart)) &&
        time.isBefore(checkEnd);
  }
}

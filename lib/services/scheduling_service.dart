import '../models/task.dart';
import '../models/blocking_period.dart';
import '../models/preferences.dart';
import '../database/database_helper.dart';
import 'routine_service.dart';

class SchedulingService {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final RoutineService _routineService = RoutineService();

  // Schedule tasks for a specific date using priority-first algorithm
  Future<ScheduleResult> scheduleTasks(DateTime date) async {
    final tasks = await _db.getTasksByStatus('unscheduled');
    final blockingPeriods = await _db.getBlockingPeriodsForDate(date);
    final preferences = await _db.getPreferences();

    // Also get already scheduled tasks for this date (to preserve them)
    final scheduledTasks = await _db.getTasksForDate(date);

    // Combine and sort all tasks by priority (9 = highest)
    final allTasks = [...scheduledTasks, ...tasks];
    allTasks.sort((a, b) {
      // Locked tasks come first regardless of priority
      if (a.lockedStartTime != null && b.lockedStartTime == null) return -1;
      if (a.lockedStartTime == null && b.lockedStartTime != null) return 1;
      
      // Then by priority (highest first)
      if (a.priority != b.priority) return b.priority.compareTo(a.priority);
      
      // Then by creation date (earlier first)
      return a.createdAt.compareTo(b.createdAt);
    });

    // Build time slots for the day (5-minute increments)
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59);
    final slots = _buildTimeSlots(startOfDay, endOfDay, blockingPeriods, date);
    final workHours = await _routineService.getWorkHours();
    final downtime = await _routineService.getDowntime();
    for (final slot in slots) {
      final minute = slot.time.hour * 60 + slot.time.minute;
      if (minute < workHours.startMinutes || minute >= workHours.endMinutes) {
        slot.isAvailable = false;
      }
      for (final period in downtime) {
        final frequency = period['frequency'] as String? ?? 'daily';
        final appliesToday = frequency == 'daily' ||
            (frequency == 'weekdays' && date.weekday <= DateTime.friday) ||
            (frequency == 'weekends' && date.weekday >= DateTime.saturday);
        if (appliesToday &&
          minute >= (period['start'] as int) &&
          minute < (period['end'] as int)) {
          slot.isAvailable = false;
        }
      }
    }

    // Schedule tasks into slots
    final scheduledTasksList = <Task>[];
    final unscheduledTasksList = <Task>[];
    final displacedTasks = <Task>[];

    for (final task in allTasks) {
      // Skip completed tasks
      if (task.status == 'complete') continue;

      // Handle locked start time
      if (task.lockedStartTime != null) {
        final lockedDate = DateTime(
          task.lockedStartTime!.year,
          task.lockedStartTime!.month,
          task.lockedStartTime!.day,
        );
        
        // Only schedule if locked time is on this date
        if (lockedDate.year == date.year &&
            lockedDate.month == date.month &&
            lockedDate.day == date.day) {
          
          if (_canFitTask(task, task.lockedStartTime!, slots)) {
            final updatedTask = task.copyWith(
              scheduledStartTime: task.lockedStartTime,
              status: 'scheduled',
            );
            _occupySlots(task.lockedStartTime!, task.durationMinutes, slots, preferences);
            scheduledTasksList.add(updatedTask);
            await _db.updateTask(updatedTask);
          } else {
            // Locked task can't fit - this is a conflict
            unscheduledTasksList.add(task);
          }
        }
        continue;
      }

      // Find next available slot for flexible task
      final availableSlot = _findNextAvailableSlot(
        task.durationMinutes,
        slots,
        startOfDay,
        preferences,
      );

      if (availableSlot != null) {
        final updatedTask = task.copyWith(
          scheduledStartTime: availableSlot,
          status: 'scheduled',
        );
        _occupySlots(availableSlot, task.durationMinutes, slots, preferences);
        scheduledTasksList.add(updatedTask);
        await _db.updateTask(updatedTask);
      } else {
        // Can't fit task
        unscheduledTasksList.add(task);
      }
    }

    return ScheduleResult(
      scheduledTasks: scheduledTasksList,
      unscheduledTasks: unscheduledTasksList,
      date: date,
    );
  }

  // Build 5-minute time slots for the day
  List<TimeSlot> _buildTimeSlots(
    DateTime start,
    DateTime end,
    List<BlockingPeriod> blockingPeriods,
    DateTime forDate,
  ) {
    final slots = <TimeSlot>[];
    var current = start;

    while (current.isBefore(end)) {
      bool isBlocked = false;

      // Check if this time is blocked
      for (final period in blockingPeriods) {
        if (period.blocksTime(current, forDate: forDate)) {
          isBlocked = true;
          break;
        }
      }

      slots.add(TimeSlot(
        time: current,
        isAvailable: !isBlocked,
      ));

      current = current.add(const Duration(minutes: 5));
    }

    return slots;
  }

  // Check if task can fit at specific time
  bool _canFitTask(Task task, DateTime startTime, List<TimeSlot> slots) {
    final slotsNeeded = (task.durationMinutes / 5).ceil();
    final startSlotIndex = slots.indexWhere((slot) => slot.time == startTime);

    if (startSlotIndex == -1) return false;
    if (startSlotIndex + slotsNeeded > slots.length) return false;

    // Check if all required slots are available
    for (int i = 0; i < slotsNeeded; i++) {
      if (!slots[startSlotIndex + i].isAvailable) {
        return false;
      }
    }

    return true;
  }

  // Find next available slot that can fit the task
  DateTime? _findNextAvailableSlot(
    int durationMinutes,
    List<TimeSlot> slots,
    DateTime startOfDay,
    Preferences preferences,
  ) {
    final slotsNeeded = (durationMinutes / 5).ceil();
    final bufferSlots = preferences.addBufferBetweenTasks ? 1 : 0;

    for (int i = 0; i <= slots.length - slotsNeeded; i++) {
      // Check if this position has enough consecutive available slots
      bool canFit = true;
      
      for (int j = 0; j < slotsNeeded + bufferSlots; j++) {
        if (i + j >= slots.length || !slots[i + j].isAvailable) {
          canFit = false;
          break;
        }
      }

      if (canFit) {
        return slots[i].time;
      }
    }

    return null;
  }

  // Occupy time slots for a task
  void _occupySlots(
    DateTime startTime,
    int durationMinutes,
    List<TimeSlot> slots,
    Preferences preferences,
  ) {
    final slotsNeeded = (durationMinutes / 5).ceil();
    final bufferSlots = preferences.addBufferBetweenTasks ? 1 : 0;
    final startSlotIndex = slots.indexWhere((slot) => slot.time == startTime);

    if (startSlotIndex == -1) return;

    for (int i = 0; i < slotsNeeded + bufferSlots && startSlotIndex + i < slots.length; i++) {
      slots[startSlotIndex + i].isAvailable = false;
    }
  }

  // Reschedule a missed task
  Future<void> rescheduleTask(Task task) async {
    // Mark as missed
    final missedTask = task.copyWith(status: 'missed');
    await _db.updateTask(missedTask);

    // Find next available date to schedule
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final unscheduledTask = missedTask.copyWith(
      status: 'unscheduled',
      scheduledStartTime: null,
    );
    await _db.updateTask(unscheduledTask);

    // Re-run scheduling for tomorrow
    await scheduleTasks(tomorrow);
  }

  // Handle overflow based on user preference
  Future<void> handleOverflow(
    List<Task> unscheduledTasks,
    DateTime currentDate,
    String overflowHandling,
  ) async {
    switch (overflowHandling) {
      case 'push_next_day':
        final nextDay = currentDate.add(const Duration(days: 1));
        await scheduleTasks(nextDay);
        break;
      case 'unscheduled_section':
        // Tasks remain in unscheduled status
        break;
      case 'prompt':
        // UI will handle prompting user
        break;
    }
  }
}

// Time slot representation
class TimeSlot {
  final DateTime time;
  bool isAvailable;

  TimeSlot({
    required this.time,
    required this.isAvailable,
  });
}

// Result of scheduling operation
class ScheduleResult {
  final List<Task> scheduledTasks;
  final List<Task> unscheduledTasks;
  final DateTime date;

  ScheduleResult({
    required this.scheduledTasks,
    required this.unscheduledTasks,
    required this.date,
  });

  bool get hasUnscheduledTasks => unscheduledTasks.isNotEmpty;
}

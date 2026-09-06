import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../database/database_helper.dart';
import '../services/scheduling_service.dart';
import '../models/recurring_task.dart';
import '../services/routine_service.dart';

class AddTaskView extends StatefulWidget {
  final Task? taskToEdit;

  const AddTaskView({super.key, this.taskToEdit});

  @override
  State<AddTaskView> createState() => _AddTaskViewState();
}

class _AddTaskViewState extends State<AddTaskView> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _db = DatabaseHelper.instance;
  final SchedulingService _schedulingService = SchedulingService();
  final RoutineService _routineService = RoutineService();

  late TextEditingController _titleController;
  late TextEditingController _durationController;
  int _durationMinutes = 30;
  int _priority = 5;
  String _category = 'personal';
  bool _hasLockedTime = false;
  DateTime? _lockedStartTime;
  bool _isFlexible = true;
  bool _isLoading = false;
  String _repeatFrequency = 'once';
  TimeOfDay? _repeatLockedTime;
  int _selectedWeekday = DateTime.monday;

  final List<String> _categories = ['personal', 'work', 'school', 'leisure'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.taskToEdit?.title ?? '');
    _durationMinutes = widget.taskToEdit?.durationMinutes ?? 30;
    _durationController = TextEditingController(
      text: _formatDuration(_durationMinutes),
    );
    _selectedWeekday = DateTime.now().weekday;
    
    if (widget.taskToEdit != null) {
      _priority = widget.taskToEdit!.priority;
      _category = widget.taskToEdit!.category;
      _hasLockedTime = widget.taskToEdit!.lockedStartTime != null;
      _lockedStartTime = widget.taskToEdit!.lockedStartTime;
      _isFlexible = widget.taskToEdit!.isFlexible;
    } else {
      _loadDefaultCategory();
    }
  }

  Future<void> _loadDefaultCategory() async {
    final prefs = await _db.getPreferences();
    setState(() {
      _category = prefs.defaultCategory;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  int? _readDuration() {
    final value = _durationController.text.trim().toLowerCase();
    final match = RegExp(r'^(?:(\d+)\s*h)?\s*(?:(\d+)\s*m)?$').firstMatch(value);
    if (match == null || (match.group(1) == null && match.group(2) == null)) {
      return null;
    }
    final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
    if (match.group(1) != null && minutes > 59) return null;
    final totalMinutes = hours * 60 + minutes;
    return totalMinutes > 0 ? totalMinutes : null;
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (hours == 0) return '${remainder}m';
    if (remainder == 0) return '${hours}h';
    return '${hours}h ${remainder}m';
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    final duration = _readDuration();
    if (duration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a duration greater than zero, such as 90m or 1h 30m.')),
      );
      return;
    }

    _durationMinutes = duration;

    setState(() => _isLoading = true);

    try {
      final task = Task(
        id: widget.taskToEdit?.id,
        title: _titleController.text.trim(),
        durationMinutes: _durationMinutes,
        priority: _priority,
        category: _category,
        lockedStartTime: _hasLockedTime ? _lockedStartTime : null,
        isFlexible: _isFlexible,
        createdAt: widget.taskToEdit?.createdAt ?? DateTime.now(),
        status: 'unscheduled',
      );

      if (widget.taskToEdit == null) {
        await _db.insertTask(task);

        if (_repeatFrequency != 'once') {
          final recurringTasks = await _routineService.getRecurringTasks();
          recurringTasks.add(RecurringTask(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            title: task.title,
            durationMinutes: task.durationMinutes,
            priority: task.priority,
            category: task.category,
            frequency: _repeatFrequency,
            recurrenceWeekday: _repeatFrequency == 'weekly'
              ? _selectedWeekday
              : null,
            lockedStartMinutes: _repeatLockedTime == null
              ? null
              : _repeatLockedTime!.hour * 60 + _repeatLockedTime!.minute,
            createdAt: DateTime.now(),
          ));
          await _routineService.saveRecurringTasks(recurringTasks);
        }

        // Scheduling is best-effort; the task is already safely saved.
        try {
          final prefs = await _db.getPreferences();
          final targetDate = prefs.defaultTaskStartDay == 'tomorrow'
              ? DateTime.now().add(const Duration(days: 1))
              : DateTime.now();
          await _schedulingService.scheduleTasks(targetDate);
        } catch (error) {
          debugPrint('Task saved, but scheduling failed: $error');
        }
      } else {
        await _db.updateTask(task);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save task. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _lockedStartTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_lockedStartTime ?? DateTime.now()),
    );

    if (time == null) return;

    setState(() {
      _lockedStartTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.taskToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'Add Task'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.task),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Please enter a task title'
                  : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Duration'),
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'How long will this take?',
                hintText: 'Examples: 1h 30m, 45m, 2h',
                helperText: 'Try 45m, 1h, 90m, or 1h 30m. No input limit.',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timer_outlined),
              ),
              keyboardType: TextInputType.text,
              validator: (_) => _readDuration() == null
                  ? 'Enter a duration like 1h 30m'
                  : null,
            ),
            const SizedBox(height: 16),
            if (!isEditing) ...[
              _buildSectionTitle('Repeat'),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: const [
                  ('once', 'Once'),
                  ('daily', 'Daily'),
                  ('weekly', 'Weekly'),
                  ('workdays', 'Workdays'),
                  ('schooldays', 'Schooldays'),
                  ('days_off', 'Days off'),
                ].map((option) {
                  return ChoiceChip(
                    label: Text(option.$2),
                    selected: _repeatFrequency == option.$1,
                    onSelected: (_) => setState(() => _repeatFrequency = option.$1),
                  );
                }).toList(),
              ),
              if (_repeatFrequency != 'once')
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _repeatDescription(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              if (_repeatFrequency == 'weekly')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 6,
                    children: List.generate(7, (index) {
                      final day = index + 1;
                      return ChoiceChip(
                        label: Text(_weekdayShortName(day)),
                        selected: _selectedWeekday == day,
                        onSelected: (_) => setState(() => _selectedWeekday = day),
                      );
                    }),
                  ),
                ),
              if (_repeatFrequency != 'once')
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.lock_clock, size: 20),
                  title: const Text('Lock repeating time'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_repeatLockedTime != null)
                        TextButton(
                          onPressed: () async {
                            final selected = await showTimePicker(
                              context: context,
                              initialTime: _repeatLockedTime!,
                            );
                            if (selected != null) {
                              setState(() => _repeatLockedTime = selected);
                            }
                          },
                          child: Text(_repeatLockedTime!.format(context)),
                        ),
                      Switch(
                        value: _repeatLockedTime != null,
                        onChanged: (value) async {
                      if (!value) {
                        setState(() => _repeatLockedTime = null);
                        return;
                      }
                      final selected = await showTimePicker(
                        context: context,
                        initialTime: _repeatLockedTime ?? const TimeOfDay(hour: 9, minute: 0),
                      );
                      if (selected != null) {
                        setState(() => _repeatLockedTime = selected);
                      }
                    },
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
            ],
            _buildSectionTitle('Priority (9 = Highest)'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Priority: $_priority'),
                        Text('P$_priority'),
                      ],
                    ),
                    Slider(
                      value: _priority.toDouble(),
                      min: 1,
                      max: 9,
                      divisions: 8,
                      label: 'P$_priority',
                      onChanged: (value) => setState(() => _priority = value.round()),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Category'),
            Card(
              child: Column(
                children: _categories.map((category) {
                  return RadioListTile<String>(
                    title: Text(category.toUpperCase()),
                    value: category,
                    groupValue: _category,
                    onChanged: (value) {
                      if (value != null) setState(() => _category = value);
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Scheduling'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Lock to a specific date and time'),
                    subtitle: const Text('Task must start on the chosen day and time'),
                    value: _hasLockedTime,
                    onChanged: (value) => setState(() {
                      _hasLockedTime = value;
                      if (value && _lockedStartTime == null) {
                        _lockedStartTime = DateTime.now().add(const Duration(days: 1));
                      }
                    }),
                  ),
                  if (_hasLockedTime)
                    ListTile(
                      title: const Text('Date and time'),
                      subtitle: Text(_lockedStartTime == null
                          ? 'Not set'
                          : DateFormat('MMM d, y - h:mm a').format(_lockedStartTime!)),
                      trailing: const Icon(Icons.schedule),
                      onTap: _selectDateTime,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cancelButton = OutlinedButton.icon(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                label: const Text('Cancel'),
              );
              final saveButton = FilledButton.icon(
                onPressed: _isLoading ? null : _saveTask,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_isLoading ? 'Saving...' : 'Save task'),
              );

              if (constraints.maxWidth < 360) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    saveButton,
                    const SizedBox(height: 8),
                    cancelButton,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  cancelButton,
                  const SizedBox(width: 12),
                  saveButton,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  String _repeatDescription() {
    switch (_repeatFrequency) {
      case 'daily':
        return 'Repeats every day. A locked time stays the same each day.';
      case 'weekly':
        return 'Repeats every ${DateFormat('EEEE').format(DateTime(2024, 1, _selectedWeekday))}. A locked time stays the same each week.';
      case 'workdays':
        return 'Repeats Monday-Friday. A locked time stays the same each workday.';
      case 'schooldays':
        return 'Repeats on schooldays. A locked time stays the same each schoolday.';
      case 'days_off':
        return 'Repeats on days off. A locked time stays the same each day off.';
      default:
        return '';
    }
  }

  String _weekdayShortName(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[weekday - 1];
  }

}

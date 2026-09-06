import 'package:flutter/material.dart';
import '../models/preferences.dart';
import '../database/database_helper.dart';
import '../services/routine_service.dart';

class PreferencesView extends StatefulWidget {
  const PreferencesView({super.key});

  @override
  State<PreferencesView> createState() => _PreferencesViewState();
}

class _PreferencesViewState extends State<PreferencesView> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final RoutineService _routineService = RoutineService();
  Preferences? _preferences;
  ({int startMinutes, int endMinutes})? _workHours;
  List<Map<String, dynamic>> _downtime = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await _db.getPreferences();
    final workHours = await _routineService.getWorkHours();
    final downtime = await _routineService.getDowntime();
    setState(() {
      _preferences = prefs;
      _workHours = workHours;
      _downtime = downtime;
      _isLoading = false;
    });
  }

  Future<void> _savePreferences(Preferences prefs) async {
    await _db.updatePreferences(prefs);
    setState(() => _preferences = prefs);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _preferences == null || _workHours == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferences'),
      ),
      body: ListView(
        children: [
          _buildSection(
            'Task Scheduling',
            [
              SwitchListTile(
                title: const Text('Add 5-minute buffer between tasks'),
                subtitle: const Text('Automatically add breaks between scheduled tasks'),
                value: _preferences!.addBufferBetweenTasks,
                onChanged: (value) {
                  _savePreferences(_preferences!.copyWith(
                    addBufferBetweenTasks: value,
                    updatedAt: DateTime.now(),
                  ));
                },
              ),
              ListTile(
                title: const Text('Task overflow handling'),
                subtitle: Text(_getOverflowHandlingDescription(_preferences!.overflowHandling)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showOverflowHandlingDialog(),
              ),
              ListTile(
                title: const Text('Default task start day'),
                subtitle: Text(_preferences!.defaultTaskStartDay.toUpperCase()),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showStartDayDialog(),
              ),
            ],
          ),
          _buildSection(
            'Daily Routine',
            [
              ListTile(
                title: const Text('Work hours'),
                subtitle: Text(
                  '${_timeFromMinutes(_workHours!.startMinutes).format(context)} - '
                  '${_timeFromMinutes(_workHours!.endMinutes).format(context)}',
                ),
                trailing: const Icon(Icons.schedule),
                onTap: _showWorkHoursDialog,
              ),
              ListTile(
                title: const Text('Downtime'),
                subtitle: Text(_downtime.isEmpty
                    ? 'No recurring breaks'
                    : '${_downtime.length} recurring break${_downtime.length == 1 ? '' : 's'}'),
                trailing: const Icon(Icons.free_breakfast),
                onTap: _showDowntimeDialog,
              ),
            ],
          ),
          _buildSection(
            'Display',
            [
              SwitchListTile(
                title: const Text('Use 24-hour format'),
                value: _preferences!.use24HourFormat,
                onChanged: (value) {
                  _savePreferences(_preferences!.copyWith(
                    use24HourFormat: value,
                    updatedAt: DateTime.now(),
                  ));
                },
              ),
              ListTile(
                title: const Text('Default view mode'),
                subtitle: Text(_preferences!.defaultViewMode.toUpperCase()),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showViewModeDialog(),
              ),
            ],
          ),
          _buildSection(
            'Defaults',
            [
              ListTile(
                title: const Text('Default category'),
                subtitle: Text(_preferences!.defaultCategory.toUpperCase()),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showDefaultCategoryDialog(),
              ),
            ],
          ),
          _buildSection(
            'Data',
            [
              ListTile(
                title: const Text('Reset app data'),
                subtitle: const Text('Delete all tasks and reset to defaults'),
                trailing: const Icon(Icons.warning, color: Colors.red),
                onTap: () => _showResetDialog(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }

  String _getOverflowHandlingDescription(String value) {
    switch (value) {
      case 'push_next_day':
        return 'Automatically push to next day';
      case 'unscheduled_section':
        return 'Keep in unscheduled section';
      case 'prompt':
        return 'Ask me what to do';
      default:
        return value;
    }
  }

  void _showOverflowHandlingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Task Overflow Handling'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Prompt me'),
              subtitle: const Text('Ask what to do each time'),
              value: 'prompt',
              groupValue: _preferences!.overflowHandling,
              onChanged: (value) {
                Navigator.pop(context);
                _savePreferences(_preferences!.copyWith(
                  overflowHandling: value,
                  updatedAt: DateTime.now(),
                ));
              },
            ),
            RadioListTile<String>(
              title: const Text('Push to next day'),
              subtitle: const Text('Automatically reschedule'),
              value: 'push_next_day',
              groupValue: _preferences!.overflowHandling,
              onChanged: (value) {
                Navigator.pop(context);
                _savePreferences(_preferences!.copyWith(
                  overflowHandling: value,
                  updatedAt: DateTime.now(),
                ));
              },
            ),
            RadioListTile<String>(
              title: const Text('Unscheduled section'),
              subtitle: const Text('Keep tasks unscheduled'),
              value: 'unscheduled_section',
              groupValue: _preferences!.overflowHandling,
              onChanged: (value) {
                Navigator.pop(context);
                _savePreferences(_preferences!.copyWith(
                  overflowHandling: value,
                  updatedAt: DateTime.now(),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStartDayDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default Task Start Day'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Today'),
              value: 'today',
              groupValue: _preferences!.defaultTaskStartDay,
              onChanged: (value) {
                Navigator.pop(context);
                _savePreferences(_preferences!.copyWith(
                  defaultTaskStartDay: value,
                  updatedAt: DateTime.now(),
                ));
              },
            ),
            RadioListTile<String>(
              title: const Text('Tomorrow'),
              value: 'tomorrow',
              groupValue: _preferences!.defaultTaskStartDay,
              onChanged: (value) {
                Navigator.pop(context);
                _savePreferences(_preferences!.copyWith(
                  defaultTaskStartDay: value,
                  updatedAt: DateTime.now(),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showViewModeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default View Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Day View'),
              value: 'day',
              groupValue: _preferences!.defaultViewMode,
              onChanged: (value) {
                Navigator.pop(context);
                _savePreferences(_preferences!.copyWith(
                  defaultViewMode: value,
                  updatedAt: DateTime.now(),
                ));
              },
            ),
            RadioListTile<String>(
              title: const Text('Week View'),
              value: 'week',
              groupValue: _preferences!.defaultViewMode,
              onChanged: (value) {
                Navigator.pop(context);
                _savePreferences(_preferences!.copyWith(
                  defaultViewMode: value,
                  updatedAt: DateTime.now(),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDefaultCategoryDialog() {
    final categories = ['personal', 'work', 'school', 'leisure'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: categories.map((category) {
            return RadioListTile<String>(
              title: Text(category.toUpperCase()),
              value: category,
              groupValue: _preferences!.defaultCategory,
              onChanged: (value) {
                Navigator.pop(context);
                _savePreferences(_preferences!.copyWith(
                  defaultCategory: value,
                  updatedAt: DateTime.now(),
                ));
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset App Data'),
        content: const Text(
          'This will delete all your tasks, blocking periods, and reset preferences to defaults. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _db.deleteDatabase();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('App data reset. Please restart the app.'),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _showWorkHoursDialog() async {
    final hours = await _routineService.getWorkHours();
    var start = _timeFromMinutes(hours.startMinutes);
    var end = _timeFromMinutes(hours.endMinutes);
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Work hours'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Start'),
                trailing: Text(start.format(context)),
                onTap: () async {
                  final value = await showTimePicker(
                    context: context,
                    initialTime: start,
                  );
                  if (value != null) setDialogState(() => start = value);
                },
              ),
              ListTile(
                title: const Text('End'),
                trailing: Text(end.format(context)),
                onTap: () async {
                  final value = await showTimePicker(
                    context: context,
                    initialTime: end,
                  );
                  if (value != null) setDialogState(() => end = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final startMinutes = start.hour * 60 + start.minute;
                final endMinutes = end.hour * 60 + end.minute;
                if (endMinutes <= startMinutes) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('End time must be after start time.')),
                  );
                  return;
                }
                await _routineService.saveWorkHours(startMinutes, endMinutes);
                if (mounted) setState(() => _workHours = (startMinutes: startMinutes, endMinutes: endMinutes));
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDowntimeDialog() async {
    final periods = await _routineService.getDowntime();
    var start = const TimeOfDay(hour: 12, minute: 0);
    var end = const TimeOfDay(hour: 13, minute: 0);
    var frequency = 'daily';
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add downtime'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (periods.isNotEmpty)
                ...periods.asMap().entries.map((entry) {
                  final index = entry.key;
                  final period = entry.value;
                  final startLabel = _timeFromMinutes(period['start'] as int).format(context);
                  final endLabel = _timeFromMinutes(period['end'] as int).format(context);
                  final frequencyLabel = period['frequency'] == 'weekdays'
                      ? 'Weekdays'
                      : period['frequency'] == 'weekends'
                          ? 'Weekends'
                          : 'Every day';
                  return ListTile(
                    dense: true,
                    title: Text('$startLabel - $endLabel'),
                    subtitle: Text(frequencyLabel),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Remove downtime',
                      onPressed: () async {
                        setDialogState(() => periods.removeAt(index));
                        await _routineService.saveDowntime(periods);
                        if (mounted) setState(() => _downtime = List<Map<String, dynamic>>.from(periods));
                      },
                    ),
                  );
                }),
              ListTile(
                title: const Text('Start'),
                trailing: Text(start.format(context)),
                onTap: () async {
                  final value = await showTimePicker(context: context, initialTime: start);
                  if (value != null) setDialogState(() => start = value);
                },
              ),
              ListTile(
                title: const Text('End'),
                trailing: Text(end.format(context)),
                onTap: () async {
                  final value = await showTimePicker(context: context, initialTime: end);
                  if (value != null) setDialogState(() => end = value);
                },
              ),
              DropdownButtonFormField<String>(
                initialValue: frequency,
                decoration: const InputDecoration(labelText: 'Repeats'),
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('Every day')),
                  DropdownMenuItem(value: 'weekdays', child: Text('Weekdays')),
                  DropdownMenuItem(value: 'weekends', child: Text('Weekends')),
                ],
                onChanged: (value) => setDialogState(() => frequency = value ?? 'daily'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final startMinutes = start.hour * 60 + start.minute;
                final endMinutes = end.hour * 60 + end.minute;
                if (endMinutes <= startMinutes) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('End time must be after start time.')),
                  );
                  return;
                }
                periods.add({'start': startMinutes, 'end': endMinutes, 'frequency': frequency});
                await _routineService.saveDowntime(periods);
                if (mounted) setState(() => _downtime = List<Map<String, dynamic>>.from(periods));
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  TimeOfDay _timeFromMinutes(int minutes) {
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }
}

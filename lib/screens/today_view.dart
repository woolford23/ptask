import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/blocking_period.dart';
import '../services/scheduling_service.dart';
import '../services/routine_service.dart';
import '../database/database_helper.dart';

class TodayView extends StatefulWidget {
  final VoidCallback? onAddTask;

  const TodayView({super.key, this.onAddTask});

  @override
  State<TodayView> createState() => _TodayViewState();
}

class _TodayViewState extends State<TodayView> {
  final SchedulingService _schedulingService = SchedulingService();
  final DatabaseHelper _db = DatabaseHelper.instance;
  final RoutineService _routineService = RoutineService();
  DateTime _selectedDate = DateTime.now();
  List<Task> _tasks = [];
  List<BlockingPeriod> _blockingPeriods = [];
  bool _isLoading = true;
  String? _loadError;
  String _viewMode = 'day'; // 'day' or 'week'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await _routineService.materializeForDate(_selectedDate);
      await _schedulingService.scheduleTasks(_selectedDate);
      final tasks = await _db.getTasksForDate(_selectedDate);
      final blocks = await _db.getBlockingPeriodsForDate(_selectedDate);
      final prefs = await _db.getPreferences();

      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _blockingPeriods = blocks;
        _viewMode = prefs.defaultViewMode;
        _loadError = null;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Could not load today view: $error');
      if (!mounted) return;
      setState(() {
        _loadError = 'Your schedule could not be loaded.';
        _isLoading = false;
      });
    }
  }

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    _loadData();
  }

  void _nextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
    _loadData();
  }

  void _goToToday() {
    setState(() {
      _selectedDate = DateTime.now();
    });
    _loadData();
  }

  void _toggleViewMode() {
    setState(() {
      _viewMode = _viewMode == 'day' ? 'week' : 'day';
    });
  }

  Future<void> _markTaskComplete(Task task) async {
    final updatedTask = task.copyWith(
      status: 'complete',
      completedAt: DateTime.now(),
    );
    await _db.updateTask(updatedTask);
    _loadData();
  }

  Future<void> _markTaskMissed(Task task) async {
    await _schedulingService.rescheduleTask(task);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM d, y');
    final isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

    return Scaffold(
      appBar: AppBar(
        title: Text(isToday ? 'Today' : dateFormat.format(_selectedDate)),
        actions: [
          IconButton(
            icon: Icon(_viewMode == 'day' ? Icons.view_week : Icons.view_day),
            onPressed: _toggleViewMode,
            tooltip: _viewMode == 'day' ? 'Week View' : 'Day View',
          ),
          if (!isToday)
            IconButton(
              icon: const Icon(Icons.today),
              onPressed: _goToToday,
              tooltip: 'Go to Today',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
            ? _buildLoadError()
          : Column(
              children: [
                _buildDateNavigator(),
                Expanded(
                  child: _viewMode == 'day'
                      ? _buildDayView()
                      : _buildWeekView(),
                ),
              ],
            ),
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: 16),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateNavigator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousDay,
          ),
          Text(
            DateFormat('MMM d, y').format(_selectedDate),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextDay,
          ),
        ],
      ),
    );
  }

  Widget _buildDayView() {
    if (_tasks.isEmpty && _blockingPeriods.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks scheduled',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add tasks to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
            if (widget.onAddTask != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: widget.onAddTask,
                icon: const Icon(Icons.add),
                label: const Text('Create a task'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        return _buildTaskCard(task);
      },
    );
  }

  Widget _buildTaskCard(Task task) {
    final timeFormat = DateFormat('h:mm a');
    final startTime = task.scheduledStartTime != null
        ? timeFormat.format(task.scheduledStartTime!)
        : 'Not scheduled';
    final endTime = task.scheduledStartTime != null
        ? timeFormat.format(task.endTime)
        : '';

    final priorityColor = _getPriorityColor(task.priority);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to task details
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 48,
                    decoration: BoxDecoration(
                      color: priorityColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$startTime - $endTime',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.timer,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDuration(task.durationMinutes),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Chip(
                        label: Text('P${task.priority}'),
                        backgroundColor: priorityColor.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: priorityColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.category.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _markTaskMissed(task),
                    icon: const Icon(Icons.skip_next, size: 18),
                    label: const Text('Missed'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _markTaskComplete(task),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekView() {
    return const Center(
      child: Text('Week view coming soon!'),
    );
  }

  Color _getPriorityColor(int priority) {
    if (priority >= 8) return Colors.red;
    if (priority >= 6) return Colors.orange;
    if (priority >= 4) return Colors.blue;
    return Colors.grey;
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (hours == 0) return '${remainder}m';
    if (remainder == 0) return '${hours}h';
    return '${hours}h ${remainder}m';
  }
}

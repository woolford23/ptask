import 'package:flutter/material.dart';
import '../models/task.dart';
import '../database/database_helper.dart';
import 'add_task_view.dart';

class TaskListView extends StatefulWidget {
  const TaskListView({super.key});

  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<Task> _tasks = [];
  bool _isLoading = true;
  String? _loadError;
  String _sortBy = 'priority'; // priority, date, category
  String _filterStatus = 'all'; // all, scheduled, unscheduled, complete, missed

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      List<Task> tasks;
      if (_filterStatus == 'all') {
        tasks = await _db.getAllTasks();
      } else {
        tasks = await _db.getTasksByStatus(_filterStatus);
      }

      tasks.sort((a, b) {
        switch (_sortBy) {
          case 'priority':
            return b.priority.compareTo(a.priority);
          case 'date':
            return a.createdAt.compareTo(b.createdAt);
          case 'category':
            return a.category.compareTo(b.category);
          default:
            return 0;
        }
      });

      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Could not load tasks: $error');
      if (!mounted) return;
      setState(() {
        _loadError = 'Your tasks could not be loaded.';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTask(Task task) async {
    await _db.deleteTask(task.id!);
    _loadTasks();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Tasks'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() => _sortBy = value);
              _loadTasks();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'priority', child: Text('Sort by Priority')),
              const PopupMenuItem(value: 'date', child: Text('Sort by Date')),
              const PopupMenuItem(value: 'category', child: Text('Sort by Category')),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _filterStatus = value);
              _loadTasks();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Tasks')),
              const PopupMenuItem(value: 'scheduled', child: Text('Scheduled')),
              const PopupMenuItem(value: 'unscheduled', child: Text('Unscheduled')),
              const PopupMenuItem(value: 'complete', child: Text('Complete')),
              const PopupMenuItem(value: 'missed', child: Text('Missed')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
            ? _buildLoadError()
          : _tasks.isEmpty
              ? _buildEmptyState()
              : _buildTaskList(),
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
              onPressed: _loadTasks,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        return _buildTaskListItem(task);
      },
    );
  }

  Widget _buildTaskListItem(Task task) {
    final priorityColor = _getPriorityColor(task.priority);
    final statusColor = _getStatusColor(task.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: priorityColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              'P${task.priority}',
              style: TextStyle(
                color: priorityColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Text(
          task.title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.timer, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(_formatDuration(task.durationMinutes)),
                const SizedBox(width: 12),
                Icon(Icons.category, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(task.category),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                task.status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _showDeleteConfirmation(task),
        ),
        onTap: () async {
          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => AddTaskView(taskToEdit: task),
            ),
          );
          if (changed == true && mounted) _loadTasks();
        },
      ),
    );
  }

  void _showDeleteConfirmation(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTask(task);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'complete':
        return Colors.green;
      case 'scheduled':
        return Colors.blue;
      case 'missed':
        return Colors.red;
      case 'unscheduled':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

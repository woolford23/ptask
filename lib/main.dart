import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/today_view.dart';
import 'screens/task_list_view.dart';
import 'screens/search_view.dart';
import 'screens/preferences_view.dart';
import 'screens/add_task_view.dart';
import 'screens/welcome_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const PTaskApp());
}

class PTaskApp extends StatelessWidget {
  const PTaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'pTask',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const StartupGate(),
    );
  }
}

class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  bool? _hasSeenWelcome;

  @override
  void initState() {
    super.initState();
    _loadWelcomeState();
  }

  Future<void> _loadWelcomeState() async {
    try {
      final preferences = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 5));
      if (mounted) {
        setState(() {
          _hasSeenWelcome = preferences.getBool('hasSeenWelcome') ?? false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _hasSeenWelcome = false);
      }
    }
  }

  Future<void> _completeWelcome() async {
    try {
      final preferences = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 5));
      await preferences.setBool('hasSeenWelcome', true);
    } catch (_) {
      // Continue into the app even when the local welcome flag cannot persist.
    } finally {
      if (mounted) {
        setState(() => _hasSeenWelcome = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasSeenWelcome == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return _hasSeenWelcome!
        ? const MainScreen()
        : WelcomeView(onContinue: _completeWelcome);
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int _todayRefreshToken = 0;

  late List<Widget> _screens = [
    TodayView(
      key: ValueKey('today-$_todayRefreshToken'),
      onAddTask: _showAddTaskDialog,
    ),
    const TaskListView(),
    const SearchView(),
    const PreferencesView(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _showAddTaskDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final screenHeight = MediaQuery.sizeOf(dialogContext).height;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 760,
              maxHeight: screenHeight - 48,
            ),
            child: const AddTaskView(),
          ),
        );
      },
    );

    // Refresh current screen if a task was added.
    if (result == true && mounted) {
      setState(() {
        if (_currentIndex == 0) {
          _screens[0] = TodayView(
            key: ValueKey('today-${++_todayRefreshToken}'),
            onAddTask: _showAddTaskDialog,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: _currentIndex < 2
          ? FloatingActionButton(
              onPressed: _showAddTaskDialog,
              tooltip: 'Add Task',
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.list),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/router/app_router.dart';
import 'database/database_provider.dart';
import 'features/tasks/models/task_priority.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: SlateApp(),
    ),
  );
}

class SlateApp extends ConsumerStatefulWidget {
  const SlateApp({super.key});

  @override
  ConsumerState<SlateApp> createState() => _SlateAppState();
}

class _SlateAppState extends ConsumerState<SlateApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _seedStarterData());
  }

  Future<void> _seedStarterData() async {
    try {
      final categoryRepo = ref.read(categoryRepositoryProvider);
      final taskRepo = ref.read(taskRepositoryProvider);

      var categories = await categoryRepo.getCategories();
      if (categories.isEmpty) {
        await categoryRepo.createCategory(name: 'Work', colorHex: '#3B82F6', iconName: 'briefcase');
        await categoryRepo.createCategory(name: 'Personal', colorHex: '#10B981', iconName: 'user');
        await categoryRepo.createCategory(name: 'Study', colorHex: '#8B5CF6', iconName: 'book-open');
        await categoryRepo.createCategory(name: 'Ideas', colorHex: '#F59E0B', iconName: 'lightbulb');
        categories = await categoryRepo.getCategories();
      }

      final tasks = await taskRepo.watchTasks().first;
      if (tasks.isEmpty) {
        final now = DateTime.now();
        final workCat = categories.where((c) => c.name == 'Work').firstOrNull;
        final studyCat = categories.where((c) => c.name == 'Study').firstOrNull;
        final ideasCat = categories.where((c) => c.name == 'Ideas').firstOrNull;

        // Task 1: Urgent today focus
        final t1 = await taskRepo.createTask(
          title: 'Verify offline SQLite sync queue & reachability',
          description: 'All local operations persist directly to SQLite before syncing upstream.',
          categoryId: workCat?.id,
          priority: TaskPriority.urgent,
          deadline: DateTime(now.year, now.month, now.day, 17, 0),
        );
        await taskRepo.toggleFocus(t1.id);

        // Task 2: Study / simulation
        await taskRepo.createTask(
          title: 'Test offline simulation mode in Settings (⌘5)',
          description: 'Turn off connectivity simulator, create tasks, and verify the queued status badge.',
          categoryId: studyCat?.id,
          priority: TaskPriority.high,
          deadline: DateTime(now.year, now.month, now.day, 19, 30),
        );

        // Task 3: Ideas reordering
        await taskRepo.createTask(
          title: 'Drag handle to reorder daily task sequence',
          description: 'Reorder tasks using custom drag handles for optimized focus flow.',
          categoryId: ideasCat?.id,
          priority: TaskPriority.medium,
          deadline: DateTime(now.year, now.month, now.day + 1, 14, 0),
        );

        // Task 4: Already completed item to demonstrate completed section & progress bar
        final t4 = await taskRepo.createTask(
          title: 'Explore IndexedDB local database persistence',
          description: 'Data remains completely intact across restarts and browser refreshes.',
          categoryId: workCat?.id,
          priority: TaskPriority.low,
          deadline: DateTime(now.year, now.month, now.day, 10, 0),
        );
        await taskRepo.toggleTaskCompletion(t4.id);
      }
    } catch (_) {
      // Non-critical background seed
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeNotifierProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Slate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(themeState.accentPack),
      darkTheme: AppTheme.dark(themeState.accentPack),
      themeMode: themeState.themeMode,
      routerConfig: router,
    );
  }
}

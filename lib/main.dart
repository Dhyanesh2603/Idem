import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/router/app_router.dart';
import 'database/database_provider.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _seedDefaultCategories());
  }

  Future<void> _seedDefaultCategories() async {
    try {
      final repo = ref.read(categoryRepositoryProvider);
      final categories = await repo.getCategories();
      if (categories.isEmpty) {
        await repo.createCategory(name: 'Work', colorHex: '#3B82F6', iconName: 'briefcase');
        await repo.createCategory(name: 'Personal', colorHex: '#10B981', iconName: 'user');
        await repo.createCategory(name: 'Study', colorHex: '#8B5CF6', iconName: 'book-open');
        await repo.createCategory(name: 'Ideas', colorHex: '#F59E0B', iconName: 'lightbulb');
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

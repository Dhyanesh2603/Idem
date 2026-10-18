import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: SlateApp(),
    ),
  );
}

class SlateApp extends ConsumerWidget {
  const SlateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/app_shell.dart';
import '../../features/today/screens/today_screen.dart';
import '../../features/inbox/screens/inbox_screen.dart';
import '../../features/calendar/screens/calendar_screen.dart';
import '../../features/review/screens/review_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/focus/screens/focus_screen.dart';
import '../../features/matrix/screens/matrix_screen.dart';
import '../../features/board/screens/board_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'rootNav');

/// Application Router definition using GoRouter StatefulShellRoute.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/today',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Today Workspace
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/today',
                builder: (context, state) => const TodayScreen(),
              ),
            ],
          ),
          // Branch 1: Smart Inbox
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inbox',
                builder: (context, state) => const InboxScreen(),
              ),
            ],
          ),
          // Branch 2: Calendar & Schedule
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (context, state) => const CalendarScreen(),
              ),
            ],
          ),
          // Branch 3: Priority Matrix (Eisenhower)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/matrix',
                builder: (context, state) => const MatrixScreen(),
              ),
            ],
          ),
          // Branch 4: Reflection & Review
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/review',
                builder: (context, state) => const ReviewScreen(),
              ),
            ],
          ),
          // Branch 5: Preferences & Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
          // Branch 6: Linear Kanban Board
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/board',
                builder: (context, state) => const BoardScreen(),
              ),
            ],
          ),
        ],
      ),
      // Distraction-Free Focus Mode route (Root overlay)
      GoRoute(
        path: '/focus',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: FocusScreen(),
        ),
      ),
    ],
  );
});

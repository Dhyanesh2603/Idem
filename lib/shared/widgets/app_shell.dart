import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_colors.dart';
import 'sync_status_badge.dart';
import 'command_palette.dart';
import 'quick_scratchpad_sheet.dart';
import 'workstation_header.dart';

/// Responsive application shell providing:
/// - Desktop (>= 768px): Persistent, spacious sidebar navigation with keyboard hints
/// - Mobile (< 768px): Thumb-friendly, clean bottom navigation
class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({
    super.key,
    required this.navigationShell,
  });

  void _onNavigate(int index, BuildContext context) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    // Global keyboard navigation shortcuts on desktop
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && isDesktop) {
          if (HardwareKeyboard.instance.isMetaPressed ||
              HardwareKeyboard.instance.isControlPressed) {
            switch (event.logicalKey) {
              case LogicalKeyboardKey.digit1:
                _onNavigate(0, context);
                return KeyEventResult.handled;
              case LogicalKeyboardKey.digit2:
                _onNavigate(1, context);
                return KeyEventResult.handled;
              case LogicalKeyboardKey.digit3:
                _onNavigate(2, context);
                return KeyEventResult.handled;
              case LogicalKeyboardKey.digit4:
                _onNavigate(3, context);
                return KeyEventResult.handled;
              case LogicalKeyboardKey.digit5:
                _onNavigate(4, context);
                return KeyEventResult.handled;
              case LogicalKeyboardKey.digit6:
                _onNavigate(5, context);
                return KeyEventResult.handled;
              case LogicalKeyboardKey.digit7:
              case LogicalKeyboardKey.keyB:
                _onNavigate(6, context);
                return KeyEventResult.handled;
              case LogicalKeyboardKey.keyF:
                context.push('/focus');
                return KeyEventResult.handled;
              case LogicalKeyboardKey.keyJ:
                QuickScratchpadSheet.show(context);
                return KeyEventResult.handled;
              case LogicalKeyboardKey.keyK:
                CommandPalette.show(context);
                return KeyEventResult.handled;
            }
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        body: isDesktop
            ? Row(
                children: [
                  _DesktopSidebar(
                    currentIndex: navigationShell.currentIndex,
                    onNavigate: (index) => _onNavigate(index, context),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: Column(
                      children: [
                        const WorkstationTopHeader(),
                        Expanded(child: navigationShell),
                      ],
                    ),
                  ),
                ],
              )
            : navigationShell,
        bottomNavigationBar: isDesktop
            ? null
            : NavigationBar(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: (index) => _onNavigate(index, context),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(LucideIcons.sunMedium),
                    selectedIcon: Icon(LucideIcons.sunMedium),
                    label: 'Today',
                  ),
                  NavigationDestination(
                    icon: Icon(LucideIcons.inbox),
                    selectedIcon: Icon(LucideIcons.inbox),
                    label: 'Inbox',
                  ),
                  NavigationDestination(
                    icon: Icon(LucideIcons.calendar),
                    selectedIcon: Icon(LucideIcons.calendar),
                    label: 'Calendar',
                  ),
                  NavigationDestination(
                    icon: Icon(LucideIcons.layoutGrid),
                    selectedIcon: Icon(LucideIcons.layoutGrid),
                    label: 'Matrix',
                  ),
                  NavigationDestination(
                    icon: Icon(LucideIcons.checkCheck),
                    selectedIcon: Icon(LucideIcons.checkCheck),
                    label: 'Review',
                  ),
                  NavigationDestination(
                    icon: Icon(LucideIcons.settings),
                    selectedIcon: Icon(LucideIcons.settings),
                    label: 'Settings',
                  ),
                ],
              ),
      ),
    );
  }
}

class _DesktopSidebar extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigate;

  const _DesktopSidebar({
    required this.currentIndex,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 230,
      color: context.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App Brand & Logo
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 16, top: 24, bottom: 20),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: context.accent,
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: [
                      BoxShadow(
                        color: context.accent.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      LucideIcons.layers,
                      size: 15,
                      color: ThemeData.estimateBrightnessForColor(context.accent) == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF0F1115),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'IDEM',
                        style: AppTypography.titleMedium(context.primaryText).copyWith(
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'OFFLINE-FIRST',
                        style: AppTypography.code(context.mutedText, fontSize: 8).copyWith(
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Command Palette Search Trigger
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: InkWell(
              onTap: () => CommandPalette.show(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: context.secondarySurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: context.border, width: 0.8),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.search, size: 13, color: context.mutedText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Command Palette',
                        style: AppTypography.bodySmall(context.mutedText),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: context.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: context.border, width: 0.6),
                      ),
                      child: Text('⌘K', style: AppTypography.code(context.mutedText, fontSize: 9)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Primary Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              children: [
                _SidebarItem(
                  icon: LucideIcons.sunMedium,
                  label: 'Today',
                  shortcut: '1',
                  isSelected: currentIndex == 0,
                  onTap: () => onNavigate(0),
                ),
                _SidebarItem(
                  icon: LucideIcons.inbox,
                  label: 'Inbox',
                  shortcut: '2',
                  isSelected: currentIndex == 1,
                  onTap: () => onNavigate(1),
                ),
                _SidebarItem(
                  icon: LucideIcons.calendar,
                  label: 'Calendar',
                  shortcut: '3',
                  isSelected: currentIndex == 2,
                  onTap: () => onNavigate(2),
                ),
                _SidebarItem(
                  icon: LucideIcons.layoutGrid,
                  label: 'Matrix',
                  shortcut: '4',
                  isSelected: currentIndex == 3,
                  onTap: () => onNavigate(3),
                ),
                _SidebarItem(
                  icon: LucideIcons.columns,
                  label: 'Board',
                  shortcut: 'B',
                  isSelected: currentIndex == 6,
                  onTap: () => onNavigate(6),
                ),
                _SidebarItem(
                  icon: LucideIcons.checkCheck,
                  label: 'Review',
                  shortcut: '5',
                  isSelected: currentIndex == 4,
                  onTap: () => onNavigate(4),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                _SidebarItem(
                  icon: LucideIcons.target,
                  label: 'Focus Mode',
                  shortcut: 'F',
                  isSelected: false,
                  onTap: () => context.push('/focus'),
                ),
                _SidebarItem(
                  icon: LucideIcons.feather,
                  label: 'Scratchpad',
                  shortcut: 'J',
                  isSelected: false,
                  onTap: () => QuickScratchpadSheet.show(context),
                ),
                _SidebarItem(
                  icon: LucideIcons.settings,
                  label: 'Settings',
                  shortcut: '6',
                  isSelected: currentIndex == 5,
                  onTap: () => onNavigate(5),
                ),
              ],
            ),
          ),

          // Connectivity & Sync Status Pill at bottom
          const Padding(
            padding: EdgeInsets.all(16),
            child: SyncStatusBadge(),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String shortcut;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.shortcut,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isSelected ? context.accentSubtle.withValues(alpha: 0.3) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? context.accent : context.secondaryText,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.bodyMedium(
                      isSelected ? context.primaryText : context.secondaryText,
                    ).copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: context.isDarkMode ? AppColors.darkSecondarySurface : AppColors.lightSecondarySurface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: context.border, width: 0.8),
                  ),
                  child: Text(
                    '⌘$shortcut',
                    style: AppTypography.code(context.mutedText, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mycondo/features/shared/widgets/badged_navigation_icon.dart';
import 'package:mycondo/theme/app_theme.dart';

class DashboardNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> changeActivePageIndex;
  final bool hasUnreadMessages;

  const DashboardNavigationBar({
    super.key,
    required this.currentIndex,
    required this.changeActivePageIndex,
    this.hasUnreadMessages = false,
  });

  static const _labels = <String>[
    'Home',
    'Payments',
    'Messages',
    'About',
    'Profile',
  ];

  static const _icons = <IconData>[
    Icons.home_outlined,
    Icons.payments_outlined,
    Icons.chat_bubble_outline_rounded,
    Icons.info_outline_rounded,
    Icons.person_outline_rounded,
  ];

  static const _selectedIcons = <IconData>[
    Icons.home_rounded,
    Icons.payments_rounded,
    Icons.chat_bubble_rounded,
    Icons.info_rounded,
    Icons.person_rounded,
  ];

  void _maybeHaptic() {
    if (kIsWeb) return;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        HapticFeedback.selectionClick();
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedSize(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: keyboardVisible
          ? const SizedBox.shrink()
          : Container(
              decoration: BoxDecoration(
                color: AppColors.creamWhite,
                border: Border.all(color: AppColors.softGray),
              ),
              child: SafeArea(
                top: false,
                child: NavigationBarTheme(
                  data: NavigationBarThemeData(
                    height: 70,
                    backgroundColor: AppColors.creamWhite,
                    indicatorColor: AppColors.black,
                    labelTextStyle: WidgetStateProperty.resolveWith((states) {
                      final isSelected = states.contains(WidgetState.selected);
                      return TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? AppColors.darkText : AppColors.secondaryText,
                      );
                    }),
                    iconTheme: WidgetStateProperty.resolveWith((states) {
                      final isSelected = states.contains(WidgetState.selected);
                      return IconThemeData(
                        color: isSelected ? colorScheme.onPrimary : AppColors.secondaryText,
                        size: 22,
                      );
                    }),
                  ),
                  child: NavigationBar(
                    selectedIndex: currentIndex,
                    onDestinationSelected: (index) {
                      _maybeHaptic();
                      changeActivePageIndex(index);
                    },
                    destinations: List.generate(_labels.length, (index) {
                      final label = _labels[index];
                      final showBadge = index == 2 && hasUnreadMessages;
                      return NavigationDestination(
                        label: label,
                        icon: Tooltip(
                          message: label,
                          child: BadgedNavigationIcon(
                            icon: _icons[index],
                            showBadge: showBadge,
                          ),
                        ),
                        selectedIcon: Tooltip(
                          message: label,
                          child: BadgedNavigationIcon(
                            icon: _selectedIcons[index],
                            showBadge: showBadge,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mycondo/features/shared/widgets/badged_navigation_icon.dart';

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

    return AnimatedSize(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: keyboardVisible
          ? const SizedBox.shrink()
          : Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F1F3),
                border: Border.all(color: const Color(0xFFE2E4E8)),
              ),
              child: SafeArea(
                top: false,
                child: NavigationBarTheme(
                  data: NavigationBarThemeData(
                    height: 70,
                    backgroundColor: const Color(0xFFF0F1F3),
                    indicatorColor: Colors.black,
                    labelTextStyle: MaterialStateProperty.resolveWith((states) {
                      final isSelected = states.contains(MaterialState.selected);
                      return TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.black : Colors.black54,
                      );
                    }),
                    iconTheme: MaterialStateProperty.resolveWith((states) {
                      final isSelected = states.contains(MaterialState.selected);
                      return IconThemeData(
                        color: isSelected ? Colors.white : Colors.black54,
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

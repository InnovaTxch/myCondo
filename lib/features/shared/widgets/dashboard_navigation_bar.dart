import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mycondo/features/shared/widgets/badged_navigation_icon.dart';
import 'package:mycondo/theme/app_theme.dart';

class DashboardNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> changeActivePageIndex;
  final bool hasUnreadMessages;
  final bool hasPaymentNotification; // NEW: badge on the Payments tab

  const DashboardNavigationBar({
    super.key,
    required this.currentIndex,
    required this.changeActivePageIndex,
    this.hasUnreadMessages = false,
    this.hasPaymentNotification = false, // NEW
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
      default:
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
                color: AppColors.lightBlueBackground,
                border: Border(
                  top: BorderSide(
                    color: AppColors.primaryBlue.withOpacity(0.12),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: NavigationBarTheme(
                  data: NavigationBarThemeData(
                    height: 68,
                    backgroundColor: Colors.transparent,
                    indicatorColor: AppColors.primaryBlue,
                    indicatorShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    labelTextStyle: WidgetStateProperty.resolveWith((states) {
                      final isSelected = states.contains(WidgetState.selected);
                      return TextStyle(
                        fontFamily: "Urbanist",
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primaryBlue
                            : AppColors.secondaryText,
                      );
                    }),
                    iconTheme: WidgetStateProperty.resolveWith((states) {
                      final isSelected = states.contains(WidgetState.selected);
                      return IconThemeData(
                        color: isSelected
                            ? AppColors.pureWhite
                            : AppColors.secondaryText,
                        size: 22,
                      );
                    }),
                  ),
                  child: NavigationBar(
                    selectedIndex: currentIndex,
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    onDestinationSelected: (index) {
                      _maybeHaptic();
                      changeActivePageIndex(index);
                    },
                    destinations: List.generate(_labels.length, (index) {
                      final label = _labels[index];
                      // index 1 = Payments, index 2 = Messages
                      final showBadge =
                          (index == 1 && hasPaymentNotification) || // NEW
                          (index == 2 && hasUnreadMessages);
                      return NavigationDestination(
                        label: label,
                        icon: BadgedNavigationIcon(
                          icon: _icons[index],
                          showBadge: showBadge,
                        ),
                        selectedIcon: BadgedNavigationIcon(
                          icon: _selectedIcons[index],
                          showBadge: showBadge,
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
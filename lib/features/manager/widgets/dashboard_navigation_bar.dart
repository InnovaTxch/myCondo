import 'package:flutter/material.dart';

class DashboardNavigationBar extends StatefulWidget {
   const DashboardNavigationBar({super.key});

  @override
  State<DashboardNavigationBar> createState() => _DashboardNavigationBar();
}


class _DashboardNavigationBar extends State<DashboardNavigationBar> {
  final List<(IconData, String)> navigationItems = [
    (Icons.home_outlined, "/manager-dashboard"),
    (Icons.access_time_outlined, "/manager-transaction"),
    (Icons.chat_bubble_outline_rounded, "/manager-chat"),
    (Icons.info_outline_rounded, "/manager-about"),
    (Icons.person_outline_rounded, "/manager-profile"),
  ];

  static int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16), 
        child: Container(
          height: 66,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F1F3),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE2E4E8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(navigationItems.length, (index) {
              final icon = navigationItems[index].$1;
              final route = navigationItems[index].$2;
              final isSelected = index == selectedIndex;

              return Expanded(
                child: Center(
                  child: InkWell(
                    onTap: () {
                      setState(() => selectedIndex = index);
                      Navigator.pushReplacementNamed(context, route);
                    },
                    borderRadius: BorderRadius.circular(999),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: isSelected
                            ? const []
                            : const [
                                BoxShadow(
                                  color: Color(0x0F000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Icon(
                        icon,
                        size: 22,
                        color: isSelected ? Colors.white : theme.iconTheme.color,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
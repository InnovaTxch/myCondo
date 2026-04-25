import 'package:flutter/material.dart';

class DashboardNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> changeActivePageIndex;

  const DashboardNavigationBar({
    super.key,
    required this.currentIndex,
    required this.changeActivePageIndex,
  });

  final List<IconData> navigationItems = const [
    Icons.home_outlined,
    Icons.access_time_outlined,
    Icons.chat_bubble_outline_rounded,
    Icons.info_outline_rounded,
    Icons.person_outline_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F3),
        border: Border.all(color: const Color(0xFFE2E4E8)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(navigationItems.length, (index) {
              final isSelected = index == currentIndex;

              return Expanded(
                child: InkWell(
                  onTap: () => changeActivePageIndex(index),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        navigationItems[index],
                        size: 22,
                        color: isSelected ? Colors.white : Colors.black54,
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

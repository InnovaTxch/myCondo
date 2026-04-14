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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Container(
          height: 66,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F1F3),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE2E4E8)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(navigationItems.length, (index) {
              // Use the index from the parent, not a static variable
              final isSelected = index == currentIndex; 

              return Expanded(
                child: InkWell(
                  onTap: () => changeActivePageIndex(index), // Pass the index back
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
import 'package:flutter/material.dart';

import 'dashboard_models.dart';

class DashboardNavigationBar extends StatelessWidget {
  const DashboardNavigationBar({
    super.key,
    required this.items,
    required this.selectedIndex,
  });

  final List<DashboardNavigationItem> items;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F3),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E4E8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = index == selectedIndex;

          return Expanded(
            child: Center(
              child: InkWell(
                onTap: item.onTap,
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
                    item.icon,
                    size: 22,
                    color: isSelected ? Colors.white : theme.iconTheme.color,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

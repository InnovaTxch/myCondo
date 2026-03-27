import 'package:flutter/material.dart';

import 'dashboard_models.dart';

class DashboardQuickActionTile extends StatelessWidget {
  const DashboardQuickActionTile({
    super.key,
    required this.action,
  });

  final DashboardQuickAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE8E4DD)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              _QuickActionIcon(
                icon: action.icon,
                badgeColor: action.iconBadgeColor,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                            height: 1.1,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      action.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: const Color(0xFF8A8A8A),
                            height: 1.25,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: Color(0xFFD7D3CC),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionIcon extends StatelessWidget {
  const _QuickActionIcon({
    required this.icon,
    this.badgeColor,
  });

  final IconData icon;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 34,
              color: Colors.black,
            ),
          ),
          if (badgeColor != null)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

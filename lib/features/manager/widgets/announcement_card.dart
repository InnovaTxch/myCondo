import 'package:flutter/material.dart';
import 'package:mycondo/data/models/manager/announcement_models.dart';
import 'package:intl/intl.dart';

class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({
    super.key,
    required this.announcement,
    required this.onEdit,
    required this.onDelete,
  });

  final Announcement announcement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const Map<String, _CategoryStyle> _styles = {
    'urgent': _CategoryStyle(
      icon: Icons.warning_rounded,
      tint: Color(0xFFCC3333),
      background: Color(0xFFFDEDED),
      iconBg: Color(0xFFE05555),
    ),
    'reminder': _CategoryStyle(
      icon: Icons.access_time_rounded,
      tint: Color(0xFFB07D10),
      background: Color(0xFFFFF8E6),
      iconBg: Color(0xFFE8A020),
    ),
    'info': _CategoryStyle(
      icon: Icons.wifi_rounded,
      tint: Color(0xFF1A73C8),
      background: Color(0xFFEBF3FD),
      iconBg: Color(0xFF3A8FE8),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final style = _styles[announcement.category] ?? _styles['info']!;
    final postedDate = DateFormat("MMM d, yyyy 'at' h:mm a")
        .format(announcement.createdAt.toLocal());

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEAEA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category icon badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: style.iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(style.icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  announcement.title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: style.tint,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Posted on $postedDate',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF999999),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  announcement.message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF444444),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Action buttons
          Column(
            children: [
              _ActionIconButton(
                icon: Icons.delete_outline_rounded,
                onTap: onDelete,
                color: const Color(0xFFAAAAAA),
              ),
              const SizedBox(height: 4),
              _ActionIconButton(
                icon: Icons.edit_outlined,
                onTap: onEdit,
                color: const Color(0xFFAAAAAA),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _CategoryStyle {
  final IconData icon;
  final Color tint;
  final Color background;
  final Color iconBg;

  const _CategoryStyle({
    required this.icon,
    required this.tint,
    required this.background,
    required this.iconBg,
  });
}
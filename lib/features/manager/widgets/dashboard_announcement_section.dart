 import 'package:flutter/material.dart';

import 'dashboard_models.dart';
import 'dashboard_skeleton_block.dart';

class DashboardAnnouncementSection extends StatelessWidget {
  const DashboardAnnouncementSection({
    super.key,
    required this.announcements,
    this.onAddAnnouncement,
  });

  final List<DashboardAnnouncement> announcements;
  final VoidCallback? onAddAnnouncement;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6E3DE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 4, 10),
            child: Row(
              children: [
                Text(
                  'Announcements',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                ),
                const Spacer(),
                InkWell(
                  onTap: onAddAnnouncement,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3F5F8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.black, size: 20),
                  ),
                ),
              ],
            ),
          ),
          if (announcements.isNotEmpty)
            ...announcements.map(
              (announcement) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _AnnouncementCard(announcement: announcement),
              ),
            )
          else
            const _AnnouncementPlaceholderCard(),
        ],
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement});

  final DashboardAnnouncement announcement;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        color: announcement.backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(announcement.icon, color: announcement.tint, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    announcement.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: announcement.tint,
                          letterSpacing: 0.15,
                        ),
                  ),
                ),
              ),
              InkWell(
                onTap: announcement.onEdit,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.edit_outlined,
                    color: announcement.tint,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            announcement.message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: announcement.tint,
                  height: 1.25,
                ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementPlaceholderCard extends StatelessWidget {
  const _AnnouncementPlaceholderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardSkeletonBlock(width: 150, height: 18),
          SizedBox(height: 14),
          DashboardSkeletonBlock(width: double.infinity, height: 12),
          SizedBox(height: 8),
          DashboardSkeletonBlock(width: 180, height: 12),
        ],
      ),
    );
  }
}

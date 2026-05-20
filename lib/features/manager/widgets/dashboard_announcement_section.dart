import 'package:flutter/material.dart';
import 'package:mycondo/theme/app_theme.dart';
import 'package:mycondo/data/models/manager/dashboard_models.dart';
import 'dashboard_skeleton_block.dart';

class DashboardAnnouncementSection extends StatelessWidget {
  const DashboardAnnouncementSection({
    super.key,
    this.announcement,
    this.isLoading = false,
    this.onOpenAnnouncements,
  });

  final DashboardAnnouncement? announcement;
  final bool isLoading;
  final VoidCallback? onOpenAnnouncements;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Announcements",
              style: TextStyle(
                fontFamily: "Urbanist",
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.secondaryText,
                letterSpacing: 0.3,
              ),
            ),
            GestureDetector(
              onTap: onOpenAnnouncements,
              child: const Text(
                "See all →",
                style: TextStyle(
                  fontFamily: "Urbanist",
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (isLoading)
          const _AnnouncementPlaceholderCard()
        else if (announcement != null)
          _AnnouncementCard(announcement: announcement!)
        else
          const _NoAnnouncementCard(),
      ],
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement});

  final DashboardAnnouncement announcement;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: announcement.backgroundColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: announcement.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: announcement.tint.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(announcement.icon, color: announcement.tint, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      announcement.title,
                      style: TextStyle(
                        fontFamily: "Urbanist",
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: announcement.tint,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      announcement.message,
                      style: TextStyle(
                        fontFamily: "Urbanist",
                        fontSize: 13,
                        color: announcement.tint.withOpacity(0.80),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.open_in_new_rounded, color: announcement.tint.withOpacity(0.6), size: 16),
            ],
          ),
        ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardSkeletonBlock(width: 150, height: 16),
          SizedBox(height: 12),
          DashboardSkeletonBlock(width: double.infinity, height: 12),
          SizedBox(height: 6),
          DashboardSkeletonBlock(width: 180, height: 12),
        ],
      ),
    );
  }
}

class _NoAnnouncementCard extends StatelessWidget {
  const _NoAnnouncementCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.campaign_outlined, color: AppColors.primaryBlue, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'No announcements yet. Tap "See all" to post one.',
              style: TextStyle(
                fontFamily: "Urbanist",
                fontSize: 13,
                color: AppColors.secondaryText,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
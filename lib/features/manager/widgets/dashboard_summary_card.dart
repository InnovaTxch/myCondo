import 'package:flutter/material.dart';
import 'package:mycondo/theme/app_theme.dart';
import 'package:mycondo/data/models/manager/dashboard_models.dart';
import 'dashboard_skeleton_block.dart';

class DashboardSummaryCard extends StatelessWidget {
  const DashboardSummaryCard({super.key, required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryBlue, Color(0xFF0B72D9)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Top row: 3 metrics ────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.people_outline_rounded,
                  label: 'Residents',
                  value: summary.totalResidents?.toString(),
                ),
              ),
              _Divider(),
              Expanded(
                child: _MetricTile(
                  icon: Icons.apartment_outlined,
                  label: 'Units',
                  value: summary.totalUnits?.toString(),
                ),
              ),
              _Divider(),
              Expanded(
                child: _MetricTile(
                  icon: Icons.fact_check_outlined,
                  label: 'Pending',
                  value: summary.paymentsToReview?.toString(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Divider ───────────────────────────────────────────────
          Container(height: 1, color: Colors.white.withOpacity(0.15)),

          const SizedBox(height: 16),

          // ── Bottom row: occupancy bar ─────────────────────────────
          _OccupancyBar(
            progress: summary.occupancyPercent,
            label: summary.progressLabel ?? 'Capacity used',
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.white.withOpacity(0.20),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 6),
        if (value != null)
          Text(
            value!,
            style: const TextStyle(
              fontFamily: "Urbanist",
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1,
            ),
          )
        else
          const DashboardSkeletonBlock(width: 32, height: 24, color: Color(0x66FFFFFF)),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: "Urbanist",
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class _OccupancyBar extends StatelessWidget {
  const _OccupancyBar({required this.progress, required this.label});

  final double? progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    final hasProgress = progress != null;
    final clamped = (progress ?? 0).clamp(0.0, 1.0);
    final percent = hasProgress ? '${(clamped * 100).round()}%' : '--';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: "Urbanist",
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
            Text(
              percent,
              style: const TextStyle(
                fontFamily: "Urbanist",
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: hasProgress ? clamped : null,
            minHeight: 8,
            backgroundColor: Colors.white.withOpacity(0.20),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ],
    );
  }
}
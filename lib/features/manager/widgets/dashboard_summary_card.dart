import 'package:flutter/material.dart';

import 'package:mycondo/data/models/manager/dashboard_models.dart';
import 'dashboard_skeleton_block.dart';

class DashboardSummaryCard extends StatelessWidget {
  const DashboardSummaryCard({
    super.key,
    required this.summary,
  });

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 18, 22),
      decoration: BoxDecoration(
        color: const Color(0xFF80BDF2),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 44,
            child: Padding(
              padding: const EdgeInsets.only(left: 6, right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryMetric(
                    label: 'Total Tenants',
                    value: summary.totalTenants?.toString(),
                  ),
                  const SizedBox(height: 26),
                  _SummaryMetric(
                    label: 'Pending Reports',
                    value: summary.pendingReports?.toString(),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 1,
            height: 126,
            color: const Color(0xCCDAEEFF),
          ),
          Expanded(
            flex: 56,
            child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _SummaryMetric(
                      label: 'Payments to\nReview',
                      value: summary.paymentsToReview?.toString(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _ProgressRing(
                    progress: summary.completionPercent,
                    label: summary.progressLabel ?? "NULL",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: const Color(0xCC163A56),
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 2),
        if (value != null)
          Text(
            value!,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 34,
                  height: 1,
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                ),
          )
        else
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: DashboardSkeletonBlock(
              width: 34,
              height: 28,
              color: Color(0x99FFFFFF),
            ),
          ),
      ],
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.progress,
    required this.label,
  });

  final double? progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    final hasProgress = progress != null;
    final clampedProgress = (progress ?? 0).clamp(0, 1).toDouble();
    final percentText = hasProgress ? '${(clampedProgress * 100).round()}%' : null;

    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: CircularProgressIndicator(
              value: clampedProgress,
              strokeWidth: 6,
              backgroundColor: const Color(0xFFD9ECFB),
              valueColor: AlwaysStoppedAnimation<Color>(
                hasProgress ? Colors.black : const Color(0x80D9ECFB),
              ),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (percentText != null)
                Text(
                  percentText,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1,
                      ),
                )
              else
                const DashboardSkeletonBlock(
                  width: 38,
                  height: 16,
                  color: Color(0x99FFFFFF),
                ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 8,
                      color: const Color(0xFFDFF1FF),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

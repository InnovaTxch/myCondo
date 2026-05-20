import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mycondo/data/models/manager/unit_monthly_models.dart';
import 'package:mycondo/theme/app_theme.dart';

class UnitBillProgressBadge extends StatelessWidget {
  const UnitBillProgressBadge({
    super.key,
    required this.summary,
    this.showAmounts = true,
  });

  final UnitBillPaymentSummary summary;
  final bool showAmounts;

  @override
  Widget build(BuildContext context) {
    final color = colorFor(summary);
    final progress = summary.paymentProgress;
    final percent = (progress * 100).round();
    final currency = NumberFormat.compactCurrency(
      symbol: 'PHP ',
      decimalDigits: 0,
    );

    final progressRing = SizedBox.square(
      dimension: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 5,
            backgroundColor: const Color(0xFFE6EBF0),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Text(
            summary.hasAssignedBill ? '$percent%' : '--',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    if (!showAmounts) return progressRing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            progressRing,
            const SizedBox(width: 6),
            Text(
              statusLabelFor(summary),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          summary.hasAssignedBill
              ? '${currency.format(summary.paidAmount / 100)} / ${currency.format(summary.totalAmount / 100)}'
              : 'No bill',
          style: const TextStyle(
            color: AppColors.secondaryText,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  static Color colorFor(UnitBillPaymentSummary summary) {
    if (!summary.hasAssignedBill || !summary.hasPaymentActivity) {
      return AppColors.secondaryText;
    }
    if (summary.isFullyPaid) return AppColors.successGreen;
    if (summary.isOverdue) return AppColors.errorRed;
    if (summary.isNearDue) return AppColors.warningOrange;
    return Color.lerp(
          AppColors.secondaryText,
          AppColors.successGreen,
          summary.paymentProgress,
        ) ??
        AppColors.successGreen;
  }

  static String statusLabelFor(UnitBillPaymentSummary summary) {
    if (!summary.hasAssignedBill) return 'No bill';
    if (!summary.hasPaymentActivity) return 'No activity';
    if (summary.isFullyPaid) return 'Paid';
    if (summary.isOverdue) return 'Overdue';
    if (summary.isNearDue) return 'Due soon';
    return 'Paying';
  }
}

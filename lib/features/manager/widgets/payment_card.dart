import 'package:flutter/material.dart';
import 'package:mycondo/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:mycondo/data/models/payment_item.dart';

class PaymentCard extends StatelessWidget {
  const PaymentCard({
    super.key,
    required this.payment,
    this.onApprove,
    this.onReject,
  });

  final PaymentItem payment;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'PHP ', decimalDigits: 2);
    final dateLabel = _buildDateLabel(payment);
    final statusColors = context.appStatusColors;
    final statusColor = _statusColor(payment.status, statusColors);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD6E8F7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A90FF).withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header strip ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.07),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar circle
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      payment.residentName.isNotEmpty
                          ? payment.residentName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Name + bill info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.residentName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${payment.billType} · ${payment.room}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge + date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _statusLabel(payment.status),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Amount ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Amount',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryText,
                  ),
                ),
                Text(
                  currency.format(payment.amount / 100),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText,
                  ),
                ),
              ],
            ),
          ),

          // ── Info rows ────────────────────────────────────────
          if ((payment.proofUrl ?? '').isNotEmpty ||
              (payment.remark ?? '').isNotEmpty ||
              (payment.rejectionReason ?? '').isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Divider(height: 1, color: AppColors.softGray),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                children: [
                  if ((payment.proofUrl ?? '').isNotEmpty)
                    _InfoRow(
                      icon: Icons.image_outlined,
                      label: 'Proof',
                      value: payment.proofUrl!,
                    ),
                  if ((payment.remark ?? '').isNotEmpty)
                    _InfoRow(
                      icon: Icons.notes_outlined,
                      label: 'Remark',
                      value: payment.remark!,
                    ),
                  if ((payment.rejectionReason ?? '').isNotEmpty)
                    _InfoRow(
                      icon: Icons.cancel_outlined,
                      label: 'Reason',
                      value: payment.rejectionReason!,
                      valueColor: const Color(0xFFB3261E),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _filledButton({
    required String label,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 38,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.pureWhite,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: "Urbanist",
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.pureWhite,
          ),
        ),
      ),
    );
  }

  Widget _outlineButton({
    required String label,
    VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 38,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFB3261E),
          side: const BorderSide(color: Color(0xFFB3261E)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: "Urbanist",
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFFB3261E),
          ),
        ),
      ),
    );
  }

  String _buildDateLabel(PaymentItem payment) {
    final date = DateTime.tryParse(payment.date)?.toLocal();
    if (date == null) return payment.date;

    switch (payment.status) {
      case PaymentStatus.approved:
        return 'Paid on ${DateFormat('MMM d, yyyy').format(date)}';
      case PaymentStatus.pending:
      case PaymentStatus.rejected:
        return DateFormat('MMM d, h:mm a').format(date);
    }
  }

  String _statusLabel(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.approved:
        return 'Approved';
      case PaymentStatus.rejected:
        return 'Denied';
    }
  }

  Color _statusColor(PaymentStatus status, AppStatusColors statusColors) {
    switch (status) {
      case PaymentStatus.pending:
        return statusColors.warningStrong;
      case PaymentStatus.approved:
        return statusColors.success;
      case PaymentStatus.rejected:
        return statusColors.destructive;
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.secondaryText),
          const SizedBox(width: 6),
          SizedBox(
            width: 52,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                height: 1.25,
                color: valueColor ?? AppColors.darkText,
                fontWeight: valueColor != null ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mycondo/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:mycondo/data/models/manager/resident_bill_group.dart';

class ResidentBillCard extends StatelessWidget {
  const ResidentBillCard({
    super.key,
    required this.bill,
    required this.onPayment,
    required this.onDelete,
  });

  final ResidentBillGroup bill;
  final VoidCallback onPayment;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'PHP ', decimalDigits: 2);
    final dueDate = DateFormat('MMM d, yyyy').format(bill.dueDate);
    final latestCompletedPayment = bill.latestCompletedPayment;
    final paidOnLabel = latestCompletedPayment == null
        ? null
        : DateFormat('MMM d, yyyy').format(
            latestCompletedPayment.createdAt.toLocal(),
          );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.softGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.billType,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Urbanist',
                      ),
                    ),
                    if (bill.isUnitTargeted &&
                        (bill.targetUnitName ?? '').isNotEmpty)
                      Text(
                        'Unit ${bill.targetUnitName}',
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                _formatStatus(bill.status),
                style: TextStyle(
                  color: _statusColor(bill.status),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Due $dueDate',
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12,
            ),
          ),
          if (paidOnLabel != null) ...[
            const SizedBox(height: 2),
            Text(
              'Paid on $paidOnLabel',
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          ...bill.bills.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(child: Text(item.name)),
                  Text(currency.format(_centavosToPesos(item.amount))),
                ],
              ),
            ),
          ),
          const Divider(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                currency.format(_centavosToPesos(bill.totalAmount)),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          if (bill.paidAmount > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Paid',
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                ),
                Text(
                  currency.format(_centavosToPesos(bill.paidAmount)),
                  style: const TextStyle(color: AppColors.secondaryText),
                ),
              ],
            ),
          ],
          if (bill.isPartial) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Remaining',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  currency.format(_centavosToPesos(bill.outstandingAmount)),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: bill.isPaid ? null : onPayment,
                  icon: const Icon(Icons.payments_outlined, size: 18),
                  label: const Text('Payment'),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 48,
                height: 48,
                child: OutlinedButton(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Icon(Icons.delete_outline),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatStatus(String status) {
    final words = status
        .split('_')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}');
    return words.join(' ');
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return AppColors.successGreen;
      case 'partial':
        return AppColors.primaryBlue;
      case 'overdue':
        return AppColors.errorRed;
      default:
        return AppColors.warningOrange;
    }
  }

  double _centavosToPesos(int amount) {
    return amount / 100;
  }
}

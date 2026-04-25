import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mycondo/data/models/manager/resident_bill_group.dart';

class ResidentBillCard extends StatelessWidget {
  const ResidentBillCard({
    super.key,
    required this.bill,
  });

  final ResidentBillGroup bill;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'PHP ', decimalDigits: 2);
    final dueDate = DateFormat('MMM d, yyyy').format(bill.dueDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  bill.billType,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Urbanist',
                  ),
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
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
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
        return const Color(0xFF227A45);
      case 'overdue':
        return const Color(0xFFB3261E);
      default:
        return const Color(0xFF8A6200);
    }
  }

  double _centavosToPesos(int amount) {
    return amount / 100;
  }
}

import 'package:flutter/material.dart';
import 'package:mycondo/data/models/payment_item.dart';

class PaymentCard extends StatelessWidget {
  final PaymentItem payment;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const PaymentCard({
    super.key,
    required this.payment,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.residentName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Shared: ${payment.room}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    payment.method,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF53B1FD),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    payment.date,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              payment.amount,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildActionArea(),
        ],
      ),
    );
  }

  Widget _buildActionArea() {
    switch (payment.status) {
      case PaymentStatus.pending:
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _outlineButton(
              label: 'Reject',
              onTap: onReject,
            ),
            const SizedBox(width: 8),
            _filledButton(
              label: 'Approve',
              onTap: onApprove,
            ),
          ],
        );

      case PaymentStatus.approved:
        return _filledButton(
          label: 'Approved',
          onTap: null,
          width: 82,
        );

      case PaymentStatus.rejected:
        return _outlineButton(
          label: 'Rejected',
          onTap: null,
          width: 88,
        );
    }
  }

  Widget _filledButton({
    required String label,
    VoidCallback? onTap,
    double width = 92,
  }) {
    return SizedBox(
      width: width,
      height: 32,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF53B1FD),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Widget _outlineButton({
    required String label,
    VoidCallback? onTap,
    double width = 92,
  }) {
    return SizedBox(
      width: width,
      height: 32,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF53B1FD),
          side: const BorderSide(color: Color(0xFF53B1FD)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}
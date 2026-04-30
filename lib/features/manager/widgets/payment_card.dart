import 'package:flutter/material.dart';
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
    final date = _formatDate(payment.date);

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
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      payment.billType,
                      style: const TextStyle(
                        fontFamily: "Urbanist",
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8A8A8A),
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _statusLabel(payment.status),
                    style: TextStyle(
                      fontFamily: "Urbanist",
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _statusColor(payment.status),
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(
                      fontFamily: "Urbanist",
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF8A8A8A),
                      height: 1.0,
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
              currency.format(payment.amount / 100),
              style: const TextStyle(
                fontFamily: "Urbanist",
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                height: 1.0,
              ),
            ),
          ),
          if ((payment.proofUrl ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoRow(label: 'Proof', value: payment.proofUrl!),
          ],
          if ((payment.remark ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(label: 'Remark', value: payment.remark!),
          ],
          if ((payment.rejectionReason ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(label: 'Reason', value: payment.rejectionReason!),
          ],
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
              label: 'Deny',
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
          width: 110,
        );
      case PaymentStatus.rejected:
        return _outlineButton(
          label: 'Denied',
          onTap: null,
          width: 100,
        );
    }
  }

  Widget _filledButton({
    required String label,
    VoidCallback? onTap,
    double width = 100,
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
          style: const TextStyle(
            fontFamily: "Urbanist",
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _outlineButton({
    required String label,
    VoidCallback? onTap,
    double width = 100,
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
          style: const TextStyle(
            fontFamily: "Urbanist",
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF53B1FD),
            height: 1.0,
          ),
        ),
      ),
    );
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return DateFormat('MMM d, h:mm a').format(date.toLocal());
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

  Color _statusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return const Color(0xFF8A6200);
      case PaymentStatus.approved:
        return const Color(0xFF227A45);
      case PaymentStatus.rejected:
        return const Color(0xFFB3261E);
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 58,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF777777),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, height: 1.25),
          ),
        ),
      ],
    );
  }
}

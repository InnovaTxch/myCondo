import 'package:flutter/material.dart';

class PaymentHistoryCard extends StatelessWidget {
  final String time;
  final String label;
  final String amount;

  const PaymentHistoryCard({
    super.key,
    required this.time,
    required this.label,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontFamily: "Urbanist",
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6D6D6D),
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: "Urbanist",
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF53B1FD),
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            amount,
            style: TextStyle(
              fontFamily: "Urbanist",
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

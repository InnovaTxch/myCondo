import 'package:flutter/material.dart';
import 'package:mycondo/data/models/manager/resident_bill_group.dart';
import 'package:mycondo/data/repositories/manager/resident_bill_repository.dart';
import 'package:mycondo/features/manager/widgets/resident_bill_card.dart';

class ResidentBillsSection extends StatelessWidget {
  const ResidentBillsSection({
    super.key,
    required this.residentId,
  });

  final String residentId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ResidentBillGroup>>(
      future: ResidentBillRepository.instance.getBillsForResident(residentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Text(
            'Unable to load bills: ${snapshot.error}',
            style: const TextStyle(color: Color(0xFFB3261E)),
          );
        }

        final bills = snapshot.data ?? const <ResidentBillGroup>[];
        final openBills = bills.where((bill) => !bill.isPaid).toList();
        final paidBills = bills.where((bill) => bill.isPaid).toList();

        if (bills.isEmpty) {
          return const Text(
            'No bills attached to this resident yet.',
            style: TextStyle(color: Colors.black54),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (openBills.isNotEmpty) ...[
              const Text(
                'Open Bills',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              ...openBills.map(
                (bill) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ResidentBillCard(bill: bill),
                ),
              ),
            ],
            if (paidBills.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'Paid Bills',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              ...paidBills.map(
                (bill) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ResidentBillCard(bill: bill),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

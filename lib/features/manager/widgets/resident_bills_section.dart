import 'package:flutter/material.dart';
import 'package:mycondo/data/models/shared/bill.dart';
import 'package:mycondo/data/models/manager/resident_bill_group.dart';
import 'package:mycondo/data/repositories/manager/resident_bill_repository.dart';
import 'package:mycondo/features/manager/widgets/resident_bill_add_sheet.dart';
import 'package:mycondo/features/manager/widgets/resident_bill_card.dart';
import 'package:mycondo/features/manager/widgets/resident_bill_payment_sheet.dart';

class ResidentBillsSection extends StatefulWidget {
  const ResidentBillsSection({
    super.key,
    required this.residentId,
  });

  final String residentId;

  @override
  State<ResidentBillsSection> createState() => _ResidentBillsSectionState();
}

class _ResidentBillsSectionState extends State<ResidentBillsSection> {
  late Future<List<ResidentBillGroup>> _billsFuture;
  final ResidentBillRepository _repository = ResidentBillRepository.instance;

  @override
  void initState() {
    super.initState();
    _billsFuture = _repository.getBillsForResident(widget.residentId);
  }

  Future<void> _refresh() async {
    final future = _repository.getBillsForResident(widget.residentId);
    setState(() {
      _billsFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ResidentBillGroup>>(
      future: _billsFuture,
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 10),
              const Text(
                'No bills attached to this resident yet.',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 14),
            if (openBills.isNotEmpty) ...[
              const Text(
                'Open Bills',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              ...openBills.map(
                (bill) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ResidentBillCard(
                    bill: bill,
                    onPayment: () => _openPaymentSheet(bill),
                    onDelete: () => _confirmDelete(bill),
                  ),
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
                  child: ResidentBillCard(
                    bill: bill,
                    onPayment: () => _openPaymentSheet(bill),
                    onDelete: () => _confirmDelete(bill),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Bills',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        TextButton.icon(
          onPressed: _openAddBillSheet,
          icon: const Icon(Icons.add),
          label: const Text('Add Bill'),
        ),
      ],
    );
  }

  Future<void> _openPaymentSheet(ResidentBillGroup bill) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => ResidentBillPaymentSheet(
        bill: bill,
        onSubmit: (amount) => _repository.recordPayment(
          bill: bill,
          residentId: widget.residentId,
          amount: amount,
        ),
      ),
    );
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _openAddBillSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => ResidentBillAddSheet(
        onSubmit: ({
          required String billType,
          required DateTime dueDate,
          required List<Bill> bills,
        }) =>
            _repository.addBill(
          residentId: widget.residentId,
          billType: billType,
          dueDate: dueDate,
          bills: bills,
        ),
      ),
    );
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _confirmDelete(ResidentBillGroup bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bill'),
        content: const Text('This will remove the bill and its payments.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _repository.deleteBill(bill);
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mycondo/data/models/manager/resident_bill_group.dart';
import 'package:mycondo/data/repositories/resident/resident_service.dart';

class ResidentBillsPage extends StatefulWidget {
  const ResidentBillsPage({
    super.key,
    this.showBackButton = true,
    this.paidOnly = false,
  });

  final bool showBackButton;
  final bool paidOnly;

  @override
  State<ResidentBillsPage> createState() => _ResidentBillsPageState();
}

class _ResidentBillsPageState extends State<ResidentBillsPage> {
  final ResidentService _service = ResidentService();
  late Future<List<ResidentBillGroup>> _billsFuture;

  @override
  void initState() {
    super.initState();
    _billsFuture = _service.fetchBillsForCurrentResident();
  }

  Future<void> _refresh() async {
    final future = _service.fetchBillsForCurrentResident();
    setState(() {
      _billsFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F4),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 20, 8),
              child: Row(
                children: [
                  if (widget.showBackButton)
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.chevron_left_rounded),
                    )
                  else
                    const SizedBox(width: 12),
                  Text(
                    widget.paidOnly ? 'Transaction History' : 'Pay Bill',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<ResidentBillGroup>>(
                future: _billsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return _ErrorState(onRetry: _refresh);
                  }

                  final bills = snapshot.data ?? const <ResidentBillGroup>[];
                  final openBills = bills.where((bill) => !bill.isPaid).toList();
                  final paidBills = bills.where((bill) => bill.isPaid).toList();
                  final visibleBills = widget.paidOnly ? paidBills : bills;

                  if (visibleBills.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                        children: [
                          _EmptyState(
                            message: widget.paidOnly
                                ? 'Paid bills will appear here after approval.'
                                : 'Bills from management will appear here.',
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                      children: [
                        if (!widget.paidOnly && openBills.isNotEmpty) ...[
                          const _SectionTitle('Open Bills'),
                          ...openBills.map(
                            (bill) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _ResidentBillCard(
                                bill: bill,
                                canPay: !widget.paidOnly,
                                onPay: () => _openPaymentSheet(bill),
                              ),
                            ),
                          ),
                        ],
                        if (paidBills.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const _SectionTitle('Paid Bills'),
                          ...paidBills.map(
                            (bill) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _ResidentBillCard(
                                bill: bill,
                                canPay: false,
                                onPay: () => _openPaymentSheet(bill),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPaymentSheet(ResidentBillGroup bill) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ResidentPaymentSheet(
        bill: bill,
        onSubmit: ({
          required int amount,
          required String proofUrl,
          required String remark,
        }) =>
            _service.submitPayment(
          bill: bill,
          amount: amount,
          proofUrl: proofUrl,
          remark: remark,
        ),
      ),
    );
    if (!mounted) return;
    await _refresh();
  }
}

class _ResidentBillCard extends StatelessWidget {
  const _ResidentBillCard({
    required this.bill,
    required this.onPay,
    this.canPay = true,
  });

  final ResidentBillGroup bill;
  final VoidCallback onPay;
  final bool canPay;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'PHP ', decimalDigits: 2);
    final dueDate = DateFormat('MMM d, yyyy').format(bill.dueDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusPill(status: bill.status),
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
                  Text(currency.format(item.amount / 100)),
                ],
              ),
            ),
          ),
          const Divider(height: 22),
          _AmountRow(
            label: 'Total',
            amount: currency.format(bill.totalAmount / 100),
            isStrong: true,
          ),
          if (bill.paidAmount > 0) ...[
            const SizedBox(height: 8),
            _AmountRow(
              label: 'Approved Payments',
              amount: currency.format(bill.paidAmount / 100),
            ),
          ],
          if (bill.pendingPayment != null) ...[
            const SizedBox(height: 10),
            _NoticeBox(
              icon: Icons.hourglass_top_rounded,
              color: Color(0xFF8A6200),
              message:
                  'Payment submitted. Waiting for manager approval.',
            ),
          ],
          if (bill.latestRejectedPayment != null) ...[
            const SizedBox(height: 10),
            _NoticeBox(
              icon: Icons.cancel_outlined,
              color: Color(0xFFB3261E),
              message:
                  'Payment denied: ${bill.latestRejectedPayment!.rejectionReason ?? 'No reason provided.'}',
            ),
          ],
          if (canPay && !bill.isPaid && bill.pendingPayment == null) ...[
            const SizedBox(height: 8),
            _AmountRow(
              label: 'Amount to Pay',
              amount: currency.format(bill.outstandingAmount / 100),
              isStrong: true,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onPay,
                icon: const Icon(Icons.payments_outlined, size: 18),
                label: const Text('Pay Bill'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResidentPaymentSheet extends StatefulWidget {
  const _ResidentPaymentSheet({
    required this.bill,
    required this.onSubmit,
  });

  final ResidentBillGroup bill;
  final Future<void> Function({
    required int amount,
    required String proofUrl,
    required String remark,
  }) onSubmit;

  @override
  State<_ResidentPaymentSheet> createState() => _ResidentPaymentSheetState();
}

class _ResidentPaymentSheetState extends State<_ResidentPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _proofController = TextEditingController();
  final _remarkController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _proofController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await widget.onSubmit(
        amount: _toCentavos(_amountController.text),
        proofUrl: _proofController.text.trim(),
        remark: _remarkController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment sent for approval.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'PHP ', decimalDigits: 2);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pay Bill',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Outstanding: ${currency.format(widget.bill.outstandingAmount / 100)}',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount paid',
                  prefixText: 'PHP ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final amount = _toCentavos(value ?? '');
                  if (amount <= 0) {
                    return 'Enter an amount greater than zero.';
                  }
                  if (amount > widget.bill.outstandingAmount) {
                    return 'Amount cannot exceed the outstanding balance.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _proofController,
                decoration: const InputDecoration(
                  labelText: 'Proof of payment link or reference',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Proof of payment is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _remarkController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Remark',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit Payment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _toCentavos(String value) {
    final normalized = value.replaceAll(',', '').trim();
    final amount = double.tryParse(normalized);
    if (amount == null) return 0;
    return (amount * 100).round();
  }
}

class _NoticeBox extends StatelessWidget {
  const _NoticeBox({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    this.isStrong = false,
  });

  final String label;
  final String amount;
  final bool isStrong;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: isStrong ? FontWeight.w800 : FontWeight.w500,
      color: isStrong ? Colors.black : Colors.black54,
    );

    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(amount, style: style),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _statusColor(status).withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _formatStatus(status),
        style: TextStyle(
          color: _statusColor(status),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
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
      case 'partial':
        return const Color(0xFF1A73C8);
      case 'overdue':
        return const Color(0xFFB3261E);
      default:
        return const Color(0xFF8A6200);
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 40,
            color: Color(0xFF999999),
          ),
          const SizedBox(height: 12),
          const Text(
            'No bills yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF777777)),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OutlinedButton(
        onPressed: onRetry,
        child: const Text('Unable to load bills. Try again.'),
      ),
    );
  }
}

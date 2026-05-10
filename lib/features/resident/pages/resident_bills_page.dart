import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mycondo/data/models/manager/resident_bill_group.dart';
import 'package:mycondo/data/repositories/resident/resident_service.dart';
import 'package:mycondo/utils/app_snackbar.dart';
import 'package:mycondo/features/shared/widgets/app_states.dart';
import 'package:mycondo/features/shared/widgets/app_page.dart';

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
    return AppPageScaffold(
      backgroundColor: const Color(0xFFF8F7F4),
      body: Column(
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
                    widget.paidOnly ? 'Payment History' : 'Pay Bill',
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
                    return const AppLoadingState();
                  }

                  if (snapshot.hasError) {
                    return AppErrorState(
                      message: 'Unable to load bills. Try again.',
                      onRetry: _refresh,
                    );
                  }

                  final bills = snapshot.data ?? const <ResidentBillGroup>[];
                  final openBills = bills
                      .where((bill) => !bill.isPaid)
                      .toList();
                  final paidBills = bills.where((bill) => bill.isPaid).toList();
                  final visibleBills = widget.paidOnly ? paidBills : bills;

                  if (visibleBills.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                        children: [
                          AppEmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: 'No bills yet',
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
    );
  }

  Future<void> _openPaymentSheet(ResidentBillGroup bill) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ResidentPaymentSheet(
        bill: bill,
        onSubmit:
            ({
              required int amount,
              required String proofUrl,
              required String remark,
            }) => _service.submitPayment(
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
              message: 'Payment submitted. Waiting for manager approval.',
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
  const _ResidentPaymentSheet({required this.bill, required this.onSubmit});

  final ResidentBillGroup bill;
  final Future<void> Function({
    required int amount,
    required String proofUrl,
    required String remark,
  })
  onSubmit;

  @override
  State<_ResidentPaymentSheet> createState() => _ResidentPaymentSheetState();
}

class _ResidentPaymentSheetState extends State<_ResidentPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _proofController = TextEditingController();
  final _remarkController = TextEditingController();
  String _selectedMethod = 'GCash';
  bool _isSaving = false;

  static const _paymentMethods = [
    (label: 'GCash', icon: Icons.account_balance_wallet_outlined),
    (label: 'Cash', icon: Icons.payments_outlined),
    (label: 'Bank Transfer', icon: Icons.account_balance_outlined),
    (label: 'Scanned QR', icon: Icons.qr_code_scanner_rounded),
    (label: 'Upload QR', icon: Icons.upload_file_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _amountController.text = _formatAmount(widget.bill.outstandingAmount);
  }

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
        remark: _buildRemark(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      context.showAppSnackBar(
        const SnackBar(content: Text('Payment sent for approval.')),
      );
    } catch (e) {
      if (!mounted) return;
      context.showAppSnackBar(SnackBar(content: Text('Payment failed: $e')));
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'PHP ', decimalDigits: 2);
    final dueDate = DateFormat('MMM d, yyyy').format(widget.bill.dueDate);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF8FCFF),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
            bottom: Radius.circular(20),
          ),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4DCE4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Submit Payment',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111111),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE3EEF7)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.bill.billType,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            'Due $dueDate',
                            style: const TextStyle(
                              color: Color(0xFF66737C),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Expanded(
                            child: Text(
                              'Outstanding Balance',
                              style: TextStyle(color: Color(0xFF66737C)),
                            ),
                          ),
                          Text(
                            currency.format(
                              widget.bill.outstandingAmount / 100,
                            ),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF55AEF5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const _PaymentFormLabel('Payment Method'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final method in _paymentMethods)
                      _PaymentMethodChip(
                        label: method.label,
                        icon: method.icon,
                        isSelected: _selectedMethod == method.label,
                        onTap: () =>
                            setState(() => _selectedMethod = method.label),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(child: _PaymentFormLabel('Amount Paid')),
                    TextButton(
                      onPressed: () {
                        _amountController.text = _formatAmount(
                          widget.bill.outstandingAmount,
                        );
                      },
                      child: const Text('Pay full balance'),
                    ),
                  ],
                ),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _paymentInputDecoration(
                    hint: '0.00',
                    prefixText: 'PHP ',
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
                const SizedBox(height: 14),
                _PaymentFormLabel(_proofLabel),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _proofController,
                  decoration: _paymentInputDecoration(
                    hint: _proofHint,
                    suffixIcon: Icons.receipt_long_outlined,
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Proof or reference is required.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                const _PaymentFormLabel('Remark'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _remarkController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: _paymentInputDecoration(
                    hint: 'Optional note for the manager',
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF4FB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF1A73C8),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your payment will be marked pending until management approves it.',
                          style: TextStyle(
                            color: Color(0xFF35566E),
                            fontSize: 12,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _submit,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      _isSaving ? 'Submitting...' : 'Submit for Approval',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF55AEF5),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _proofLabel {
    switch (_selectedMethod) {
      case 'Cash':
        return 'Receipt or Cash Reference';
      case 'Bank Transfer':
        return 'Transfer Reference';
      case 'Scanned QR':
        return 'QR Payment Reference';
      case 'Upload QR':
        return 'Uploaded QR / Proof Link';
      default:
        return 'GCash Reference or Proof Link';
    }
  }

  String get _proofHint {
    switch (_selectedMethod) {
      case 'Cash':
        return 'e.g. OR #000123';
      case 'Bank Transfer':
        return 'e.g. transfer reference number';
      case 'Scanned QR':
        return 'e.g. QR transaction reference';
      case 'Upload QR':
        return 'Paste uploaded proof link';
      default:
        return 'e.g. GCash ref no. or screenshot link';
    }
  }

  String _buildRemark() {
    final note = _remarkController.text.trim();
    if (note.isEmpty) return 'Payment method: $_selectedMethod';
    return 'Payment method: $_selectedMethod\n$note';
  }

  String _formatAmount(int centavos) {
    return (centavos / 100).toStringAsFixed(2);
  }

  int _toCentavos(String value) {
    final normalized = value.replaceAll(',', '').trim();
    final amount = double.tryParse(normalized);
    if (amount == null) return 0;
    return (amount * 100).round();
  }
}

class _PaymentFormLabel extends StatelessWidget {
  const _PaymentFormLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: Color(0xFF3D4650),
      ),
    );
  }
}

class _PaymentMethodChip extends StatelessWidget {
  const _PaymentMethodChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF55AEF5) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF55AEF5)
                : const Color(0xFFE1EAF2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF3D4650),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : const Color(0xFF3D4650),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _paymentInputDecoration({
  String? hint,
  String? prefixText,
  IconData? suffixIcon,
}) {
  return InputDecoration(
    hintText: hint,
    prefixText: prefixText,
    filled: true,
    fillColor: Colors.white,
    suffixIcon: suffixIcon == null
        ? null
        : Icon(suffixIcon, color: const Color(0xFF7A8994), size: 20),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE1EAF2)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF55AEF5), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFB3261E)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFB3261E), width: 1.5),
    ),
  );
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


import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mycondo/data/models/manager/unit_monthly_models.dart';
import 'package:mycondo/data/repositories/manager/unit_billing_repository.dart';
import 'package:mycondo/features/shared/widgets/app_page.dart';
import 'package:mycondo/features/shared/widgets/app_states.dart';
import 'package:mycondo/theme/app_theme.dart';
import 'package:mycondo/utils/app_snackbar.dart';
import 'package:mycondo/utils/user_friendly_error.dart';

class ResidentUnitBillPage extends StatefulWidget {
  const ResidentUnitBillPage({super.key});

  @override
  State<ResidentUnitBillPage> createState() => _ResidentUnitBillPageState();
}

class _ResidentUnitBillPageState extends State<ResidentUnitBillPage> {
  static const int _basePage = 1200;

  final UnitBillingRepository _repository = UnitBillingRepository.instance;
  late final DateTime _baseMonth;
  late final PageController _monthController;
  DateTime _selectedMonth = _toMonth(DateTime.now());

  final Map<String, UnitMonthlyLedger> _ledgerByMonth = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _baseMonth = _toMonth(DateTime.now());
    _selectedMonth = _baseMonth;
    _monthController = PageController(
      initialPage: _basePage,
      viewportFraction: 0.95,
    );
    _loadInitial();
  }

  @override
  void dispose() {
    _monthController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _loadLedgerForMonth(_selectedMonth);
    } catch (e, st) {
      if (!mounted) return;
      debugPrint('[ResidentUnitBillPage.loadInitial] $e');
      debugPrint(st.toString());
      setState(
        () => _errorMessage = UserFriendlyError.messageFor(
          e,
          fallback: 'Unable to load unit bill.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadLedgerForMonth(DateTime month) async {
    final key = _monthKey(month);
    if (_ledgerByMonth.containsKey(key)) return;
    final ledger = await _repository.getUnitMonthlyLedgerForResident(
      month: month,
    );
    if (!mounted) return;
    setState(() => _ledgerByMonth[key] = ledger);
  }

  Future<void> _refreshLedgerForMonth(DateTime month) async {
    final key = _monthKey(month);
    setState(() => _ledgerByMonth.remove(key));
    await _loadLedgerForMonth(month);
  }

  Future<void> _openPaymentSheet(UnitMonthlyLedger ledger) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ResidentUnitPaymentSheet(
        ledger: ledger,
        onSubmit:
            ({
              required int amount,
              required String proofUrl,
              required String remark,
            }) async {
              await _repository.submitResidentUnitPayment(
                month: ledger.month,
                amount: amount,
                proofUrl: proofUrl,
                remark: remark,
              );
              await _refreshLedgerForMonth(ledger.month);
            },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      backgroundColor: AppColors.lightBlueBackground,
      appBar: AppBar(title: const Text('Unit Bill')),
      body: _isLoading
          ? const AppLoadingState()
          : _errorMessage != null
          ? AppScrollableCentered(
              child: AppErrorState(
                message: 'Unable to load unit bill.',
                details: _errorMessage,
                onRetry: _loadInitial,
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Monthly Unit Bill',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(_selectedMonth),
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _monthController,
                    onPageChanged: (index) {
                      final month = _monthForPage(index);
                      setState(() => _selectedMonth = month);
                      _loadLedgerForMonth(month);
                    },
                    itemBuilder: (context, index) {
                      final month = _monthForPage(index);
                      final key = _monthKey(month);
                      final ledger = _ledgerByMonth[key];
                      if (ledger == null) {
                        _loadLedgerForMonth(month);
                        return const Center(child: CircularProgressIndicator());
                      }
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                        child: _ResidentUnitLedgerCard(
                          ledger: ledger,
                          onPay: () => _openPaymentSheet(ledger),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  DateTime _monthForPage(int index) {
    final offset = index - _basePage;
    return DateTime(_baseMonth.year, _baseMonth.month + offset, 1);
  }

  static DateTime _toMonth(DateTime date) => DateTime(date.year, date.month, 1);

  static String _monthKey(DateTime month) =>
      '${month.year}-${month.month.toString().padLeft(2, '0')}';
}

class _ResidentUnitLedgerCard extends StatelessWidget {
  const _ResidentUnitLedgerCard({required this.ledger, required this.onPay});

  final UnitMonthlyLedger ledger;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'PHP ', decimalDigits: 2);
    final monthLabel = DateFormat('MMMM yyyy').format(ledger.month);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2ECF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  monthLabel,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (ledger.hasAssignedBill)
                Text(
                  _statusLabel(ledger.status),
                  style: TextStyle(
                    color: _statusColor(ledger.status),
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          if (!ledger.hasAssignedBill) ...[
            const SizedBox(height: 14),
            const Expanded(
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  'No unit bill has been assigned for this month.',
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total Bill Amount',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  currency.format(ledger.totalAmount / 100),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ledger.payments.isEmpty
                  ? const Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        'No approved payments yet for this month.',
                        style: TextStyle(color: AppColors.secondaryText),
                      ),
                    )
                  : ListView.separated(
                      itemCount: ledger.payments.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final payment = ledger.payments[index];
                        return Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${payment.residentName} paid on ${DateFormat('MMM d').format(payment.paidAt)}',
                              ),
                            ),
                            Text('- ${currency.format(payment.amount / 100)}'),
                          ],
                        );
                      },
                    ),
            ),
            const Divider(height: 14),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Remaining Amount',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  currency.format(ledger.remainingAmount / 100),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: ledger.remainingAmount > 0
                        ? AppColors.errorRed
                        : AppColors.successGreen,
                  ),
                ),
              ],
            ),
            if (ledger.hasPendingPayment) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Payment pending approval: ${currency.format(ledger.pendingAmount / 100)}',
                  style: const TextStyle(
                    color: AppColors.warningOrange,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            if (ledger.remainingAmount > 0 && !ledger.hasPendingPayment) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onPay,
                  icon: const Icon(Icons.payments_outlined, size: 18),
                  label: const Text('Pay Unit Bill'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'Paid';
      case 'partial':
        return 'Partial';
      case 'overdue':
        return 'Overdue';
      default:
        return 'Unpaid';
    }
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
}

class _ResidentUnitPaymentSheet extends StatefulWidget {
  const _ResidentUnitPaymentSheet({
    required this.ledger,
    required this.onSubmit,
  });

  final UnitMonthlyLedger ledger;
  final Future<void> Function({
    required int amount,
    required String proofUrl,
    required String remark,
  })
  onSubmit;

  @override
  State<_ResidentUnitPaymentSheet> createState() =>
      _ResidentUnitPaymentSheetState();
}

class _ResidentUnitPaymentSheetState extends State<_ResidentUnitPaymentSheet> {
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
    _amountController.text = _formatAmount(widget.ledger.remainingAmount);
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
    } catch (e, st) {
      if (!mounted) return;
      context.showAppError(
        e,
        stackTrace: st,
        fallbackMessage: 'Payment submission failed. Please try again.',
        debugLabel: 'ResidentUnitBillPage.submitPayment',
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'PHP ', decimalDigits: 2);
    final monthLabel = DateFormat('MMMM yyyy').format(widget.ledger.month);

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
                      color: AppColors.softGray,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Pay Unit Bill',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkText,
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
                    color: AppColors.pureWhite,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.softGray),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              monthLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Remaining Balance',
                              style: TextStyle(color: AppColors.secondaryText),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        currency.format(widget.ledger.remainingAmount / 100),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryBlue,
                        ),
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
                          widget.ledger.remainingAmount,
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
                    if (amount > widget.ledger.remainingAmount) {
                      return 'Amount cannot exceed the remaining balance.';
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
                    color: AppColors.skyBlue,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.primaryBlue,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your payment will be marked pending until management approves it.',
                          style: TextStyle(
                            color: AppColors.secondaryText,
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
                              color: AppColors.pureWhite,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      _isSaving ? 'Submitting...' : 'Submit for Approval',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: AppColors.pureWhite,
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
        color: AppColors.darkText,
        fontWeight: FontWeight.w800,
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
    final color = isSelected ? AppColors.primaryBlue : AppColors.secondaryText;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEAF3FF) : AppColors.pureWhite,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.softGray,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _paymentInputDecoration({
  required String hint,
  String? prefixText,
  IconData? suffixIcon,
}) {
  return InputDecoration(
    hintText: hint,
    prefixText: prefixText,
    suffixIcon: suffixIcon == null ? null : Icon(suffixIcon),
    filled: true,
    fillColor: AppColors.pureWhite,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.softGray),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.6),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mycondo/data/models/resident.dart';
import 'package:mycondo/data/models/shared/bill.dart';
import 'package:mycondo/data/models/unit.dart';
import 'package:mycondo/data/repositories/manager/bill_service.dart';
import 'package:mycondo/data/repositories/resident/resident_service.dart';
import 'package:mycondo/features/manager/widgets/bill_details.dart';
import 'package:mycondo/features/manager/widgets/bill_recipient_container.dart';
import 'package:mycondo/features/shared/widgets/submit_button.dart';
import 'package:mycondo/theme/app_theme.dart';
import 'package:mycondo/utils/app_snackbar.dart';

class CreateBillPage extends StatefulWidget {
  const CreateBillPage({super.key});

  @override
  State<CreateBillPage> createState() => _CreateBillPageState();
}

class _CreateBillPageState extends State<CreateBillPage> {
  static const List<String> _billTypes = <String>[
    'Monthly Bill',
    'One-Time Fee',
  ];

  final NumberFormat _pesoFormatter = NumberFormat.currency(
    symbol: 'PHP ',
    decimalDigits: 2,
    locale: 'en_PH',
  );

  final BillService _billService = BillService();
  final ResidentService _residentService = ResidentService();
  final List<Unit> _allUnits = [];
  final List<Resident> _selectedResidents = [];

  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  String? _selectedBillType = 'Monthly Bill';
  bool _isLoading = false;
  bool _isAccountabilityShared = false;

  final List<Map<String, dynamic>> _lineItems = [
    {'title': TextEditingController(), 'amount': TextEditingController()},
  ];

  @override
  void initState() {
    super.initState();
    _fetchUnits();
  }

  @override
  void dispose() {
    for (final item in _lineItems) {
      (item['title'] as TextEditingController).dispose();
      (item['amount'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  Future<void> _fetchUnits() async {
    final units = await _residentService.fetchUnitsForManager();
    if (units == null || !mounted) return;
    setState(() => _allUnits.addAll(units));
  }

  bool _isSubmissionValid() {
    if (_selectedResidents.isEmpty || _selectedBillType == null) {
      return false;
    }

    for (final item in _lineItems) {
      final title = (item['title'] as TextEditingController).text.trim();
      final amount = double.tryParse(
        (item['amount'] as TextEditingController).text.trim(),
      );
      if (title.isEmpty || amount == null || amount <= 0) {
        return false;
      }
    }
    return true;
  }

  Future<void> _generateBill() async {
    if (!_isSubmissionValid()) return;
    setState(() => _isLoading = true);

    try {
      final residentIds = _selectedResidents.map((r) => r.id).toList();
      final bills = _lineItems.map((item) {
        final title = (item['title'] as TextEditingController).text.trim();
        final amount =
            double.tryParse(
              (item['amount'] as TextEditingController).text.trim(),
            ) ??
            0;
        return Bill(name: title, amount: (amount * 100).round());
      }).toList();

      context.showAppSnackBar(
        SnackBar(content: Text('Sending $_selectedBillType...')),
      );

      await _billService.generateAndSendBills(
        billType: _selectedBillType!,
        dueDate: _dueDate,
        bills: bills,
        isAccountabilityShared: _isAccountabilityShared,
        recipientMode: BillRecipientMode.resident,
        residentIds: residentIds,
      );

      if (!mounted) return;
      context.showAppSnackBar(
        const SnackBar(content: Text('Bills sent successfully!')),
      );
    } catch (e, st) {
      if (!mounted) return;
      context.showAppError(
        e,
        stackTrace: st,
        fallbackMessage: 'Could not send bills. Please try again.',
        debugLabel: 'CreateBillPage.generateBill',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  double _calculateTotal() {
    return _lineItems.fold<double>(0, (sum, item) {
      final amount =
          double.tryParse(
            (item['amount'] as TextEditingController).text.trim(),
          ) ??
          0;
      return sum + amount;
    });
  }

  void _addLineItem() {
    setState(() {
      _lineItems.add({
        'title': TextEditingController(),
        'amount': TextEditingController(),
      });
    });
  }

  void _removeLineItem(int index) {
    if (_lineItems.length == 1) return;
    late final Map<String, dynamic> item;
    setState(() => item = _lineItems.removeAt(index));
    (item['title'] as TextEditingController).dispose();
    (item['amount'] as TextEditingController).dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlueBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Add Bills',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: 'Recipients',
                child: BillRecipientContainer(
                  selectedResidents: _selectedResidents,
                  allUnits: _allUnits,
                  onSelectionChanged: () => setState(() {}),
                ),
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: 'Bill Details',
                child: BillDetails(
                  dueDate: _dueDate,
                  selectedBillType: _selectedBillType,
                  billTypes: _billTypes,
                  setSelectedBillType: (value) =>
                      setState(() => _selectedBillType = value),
                  setDueDate: (date) => setState(() => _dueDate = date),
                ),
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: 'Line Items',
                child: Column(
                  children: [
                    ..._lineItems.asMap().entries.map(
                      (entry) => _buildLineItem(entry.key),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _addLineItem,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Line Item'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.darkText,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Amount Due',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _pesoFormatter.format(_calculateTotal()),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE6E2DD)),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Split across all residents',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Each selected resident receives an equal share.',
                  ),
                  value: _isAccountabilityShared,
                  onChanged: (val) =>
                      setState(() => _isAccountabilityShared = val),
                ),
              ),
              const SizedBox(height: 18),
              SubmitButton(
                text: 'Generate & Send Bills',
                onPressed: _isSubmissionValid() ? _generateBill : null,
                color: AppColors.darkText,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildLineItem(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _lineItems[index]['title'] as TextEditingController,
              decoration: _inputDecoration('Description'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _lineItems[index]['amount'] as TextEditingController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _inputDecoration(
                'Amount',
              ).copyWith(prefixText: 'PHP '),
              onChanged: (_) => setState(() {}),
            ),
          ),
          IconButton(
            onPressed: _lineItems.length == 1
                ? null
                : () => _removeLineItem(index),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.creamWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}

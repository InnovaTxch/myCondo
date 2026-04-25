import 'package:mycondo/data/models/unit.dart';
import 'package:mycondo/data/models/resident.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mycondo/data/repositories/resident/resident_service.dart';

import '../widgets/bill_recipient_container.dart';
import '../widgets/bill_details.dart';

import 'package:mycondo/data/models/shared/bill.dart';
import 'package:mycondo/features/shared/widgets/submit_button.dart';

import 'package:mycondo/data/repositories/manager/bill_service.dart';

class CreateBillPage extends StatefulWidget {
  const CreateBillPage({super.key});

  @override
  State<CreateBillPage> createState() => _CreateBillPageState();
}

class _CreateBillPageState extends State<CreateBillPage> {
  final _formKey = GlobalKey<FormState>();

  final pesoFormatter = NumberFormat.currency(
    symbol: "PHP ",
    decimalDigits: 2,
    locale: "en_PH",
  );

  final List<Unit> _allUnits = [];

  final _billServices = BillService();
  final _residentService = ResidentService();

  final List<Resident> _selectedResidents = [];
  String? _selectedBillType;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _isAccountabilityShared = false;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _breakdownItems = [
    {
      'title': TextEditingController(),
      'amount': TextEditingController(),
    }
  ];

  Future<void> _fetchUnits() async {
    final units = await _residentService.fetchUnitsForManager();

    if (units != null && mounted) {
      setState(() => _allUnits.addAll(units));
    }
  }

  bool _isSubmissionValid() {
    if (_selectedResidents.isEmpty ||
        _selectedBillType == null ||
        _breakdownItems.isEmpty) {
      return false;
    }

    for (var item in _breakdownItems) {
      if (item['title'].text.isEmpty || item['amount'].text.isEmpty) {
        return false;
      }
      if (double.tryParse(item['amount'].text) == null) {
        return false;
      }
    }
    return true;
  }

  Future<void> _generateBill() async {
    if (_selectedResidents.isEmpty || _selectedBillType == null) return;

    setState(() => _isLoading = true);

    try {
      List<String> residentIds = _selectedResidents.map((r) => r.id).toList();
      List<Bill> bills = _breakdownItems.map((item) {
        return Bill(
          name: item['title'].text,
          amount: ((double.tryParse(item['amount'].text) ?? 0.0) * 100).round(),
        );
      }).toList();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sending $_selectedBillType...")),
      );

      await _billServices.generateAndSendBills(
        billType: _selectedBillType!,
        residentIds: residentIds,
        dueDate: _dueDate,
        bills: bills,
        isAccountabilityShared: _isAccountabilityShared,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bills sent successfully!")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send bills: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setSelectedBillType(String? newValue) {
    setState(() => _selectedBillType = newValue);
  }

  void _setDueDate(DateTime newValue) {
    setState(() => _dueDate = newValue);
  }

  double _calculateTotal() {
    return _breakdownItems.fold(0, (sum, item) {
      return sum + (double.tryParse(item['amount'].text) ?? 0);
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchUnits();
  }

  @override
  void dispose() {
    for (final item in _breakdownItems) {
      (item['title'] as TextEditingController).dispose();
      (item['amount'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F1EC),
      body: SafeArea(
        child: Form(
          key: _formKey,
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
                      "Add Dues",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: "Recipients",
                  child: BillRecipientContainer(
                    selectedResidents: _selectedResidents,
                    allUnits: _allUnits,
                    onSelectionChanged: () => setState(() {}),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: "Bill Details",
                  child: BillDetails(
                    dueDate: _dueDate,
                    setSelectedBillType: _setSelectedBillType,
                    setDueDate: _setDueDate,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: "Line Items",
                  child: Column(
                    children: [
                      ..._breakdownItems.asMap().entries.map((entry) {
                        final index = entry.key;
                        return _buildLineItem(index);
                      }),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _addLineItem,
                          icon: const Icon(Icons.add),
                          label: const Text("Add Line Item"),
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
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Total Bill Amount",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        pesoFormatter.format(_calculateTotal()),
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
                      "Split across all residents",
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      "Each selected resident receives an equal share.",
                    ),
                    value: _isAccountabilityShared,
                    onChanged: (val) =>
                        setState(() => _isAccountabilityShared = val),
                  ),
                ),
                const SizedBox(height: 18),
                SubmitButton(
                  text: "Generate & Send Bills",
                  onPressed: _isSubmissionValid() ? _generateBill : null,
                  color: const Color(0xFF1A1A1A),
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
              color: Color(0xFF1A1A1A),
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
              controller: _breakdownItems[index]['title'],
              decoration: _inputDecoration("Description"),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _breakdownItems[index]['amount'],
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _inputDecoration("Amount").copyWith(
                prefixText: "PHP ",
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          IconButton(
            onPressed: _breakdownItems.length == 1
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
      fillColor: const Color(0xFFF7F5F2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  void _addLineItem() {
    setState(() {
      _breakdownItems.add({
        'title': TextEditingController(),
        'amount': TextEditingController(),
      });
    });
  }

  void _removeLineItem(int index) {
    late final Map<String, dynamic> item;
    setState(() {
      item = _breakdownItems.removeAt(index);
    });
    (item['title'] as TextEditingController).dispose();
    (item['amount'] as TextEditingController).dispose();
  }
}

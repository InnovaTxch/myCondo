import 'package:mycondo/data/models/unit.dart';
import 'package:mycondo/data/models/resident.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mycondo/data/repositories/resident_service.dart';

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

  
  final pesoFormatter = NumberFormat.currency(symbol: "\u{20B1}",
    decimalDigits: 2,
    locale: "en_PH"
  );

  // Mock Data
  final List<Unit> _allUnits = [];

  final _billServices = BillService();
  final _residentService = ResidentService();

  final List<Resident> _selectedResidents = [];
  String? _selectedBillType;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _isAccountabilityShared = false;
  
  final List<Map<String, dynamic>> _breakdownItems = [
    {'title': TextEditingController(), 
    'amount': TextEditingController()}
  ];

  Future<void> _fetchUnits() async {
    final units = await _residentService.fetchUnitsForManager();
    
    if (units != null) {
      setState(() => _allUnits.addAll(units));
    }
  }

  bool _isSubmissionValid() {
    if (_selectedResidents.isEmpty || _selectedBillType == null || _breakdownItems.isEmpty) {
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
    _selectedBillType = newValue;
  }

  void _setDueDate(DateTime newValue) {
    _dueDate = newValue;
  }

  double _calculateTotal() {
    return _breakdownItems.fold(0, (sum, item) {
      return sum + (double.tryParse(item['amount'].text) ?? 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text("Bill Recipients", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                
                // --- The Big Recipient Container ---
                BillRecipientContainer(
                  selectedResidents: _selectedResidents, 
                  allUnits: _allUnits,
                ),

                const SizedBox(height: 24),
                
                BillDetails(
                  dueDate: _dueDate, 
                  setSelectedBillType: _setSelectedBillType, 
                  setDueDate: _setDueDate
                ),

                const Divider(height: 40),
                // --- Breakdown Section ---
                ..._breakdownItems.asMap().entries.map((entry) {
                  int index = entry.key;
                  return Row(
                    children: [
                      Expanded(flex: 3, child: TextField(controller: _breakdownItems[index]['title'], decoration: const InputDecoration(hintText: "Description"))),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: TextField(controller: _breakdownItems[index]['amount'], keyboardType: TextInputType.number, decoration: const InputDecoration(prefixText: "\u{20B1}"), onChanged: (_) => setState(() {}))),
                      IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => setState(() => _breakdownItems.removeAt(index))),
                    ],
                  );
                }),
                TextButton.icon(onPressed: () => setState(() => _breakdownItems.add({'title': TextEditingController(), 'amount': TextEditingController()})), icon: const Icon(Icons.add), label: const Text("Add Line Item")),

                const SizedBox(height: 30),
                // --- Total & Submit ---
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blueGrey.shade900,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Bill Amount", style: TextStyle(color: Colors.white, fontSize: 16)),
                      Text(pesoFormatter.format(_calculateTotal()), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                CheckboxListTile(
                  title: const Text("Split across all residents?"),
                  value: _isAccountabilityShared, 
                  onChanged: (val) => setState(() => _isAccountabilityShared = val ?? false),
                ),

                const SizedBox(height: 16),

                SubmitButton(
                  text: "Generate & Send Bills", 
                  onPressed: _isSubmissionValid() ? () => _generateBill() : null,
                  color: Colors.blueAccent,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      )
    );
  }
}

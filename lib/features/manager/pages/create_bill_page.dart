import 'package:mycondo/data/models/unit.dart';
import 'package:mycondo/data/models/resident.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mycondo/data/repositories/resident_service.dart';

import '../widgets/bill_recipient_container.dart';
import '../widgets/bill_details.dart';

import 'package:mycondo/features/shared/widgets/submit_button.dart';
class CreateBillPage extends StatefulWidget {
  const CreateBillPage({super.key});

  @override
  State<CreateBillPage> createState() => _CreateBillPageState();
}

class _CreateBillPageState extends State<CreateBillPage> {
  final _formKey = GlobalKey<FormState>();

  final List<String> _billTypes = ["Monthly Bill", "One-Time Fee"];
  final pesoFormatter = NumberFormat.currency(symbol: "\u{20B1}",
    decimalDigits: 2,
    locale: "en_PH");

  // Mock Data
  final List<Unit> _allUnits = [];
  final _residentService = ResidentService();

  final List<Resident> _selectedResidents = [];
  String? _selectedBillType;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _isAccountabilityShared = false;
  
  final List<Map<String, dynamic>> _breakdownItems = [
    {'title': TextEditingController(), 'amount': TextEditingController()}
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

  void _addUnit(Unit u) {
    for (var member in u.members) {
      _addResident(member);
    }
  }

  double _calculateTotal() {
    return _breakdownItems.fold(0, (sum, item) {
      return sum + (double.tryParse(item['amount'].text) ?? 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create New Bill")),
      body: Form(
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
                child: Stack(
                  children: [
                    if (_selectedResidents.isEmpty)
                      const Center(child: Text("No residents selected", style: TextStyle(color: Colors.grey))),
                    
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _selectedResidents.map((r) => Chip(
                        label: Text("${r.name} (${r.unit})"),
                        onDeleted: () => setState(() => _selectedResidents.remove(r)),
                        deleteIconColor: Colors.redAccent,
                        backgroundColor: Colors.blue.shade50,
                      )).toList(),
                    ),
                    
                    // Floating Plus Button inside container (Bottom Right)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: FloatingActionButton.small(
                        onPressed: () => _showSearchModal(context),
                        child: const Icon(Icons.add),
                      ),
                    )
                  ],

                const SizedBox(height: 24),
                
                BillDetails(
                  dueDate: _dueDate, 
                  setSelectedBillType: _setSelectedBillType, 
                  setDueDate: _setDueDate
                ),
                  ),
                ],
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
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                  onPressed: _selectedResidents.isEmpty || _selectedBillType == null
                      ? null
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Sending $_selectedBillType to ${_selectedResidents.length} resident(s)",
                              ),
                            ),
                          );
                        },
                  child: const Text("Generate & Send Bills", style: TextStyle(fontSize: 16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- Search Modal ---
  void _showSearchModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: TextField(decoration: InputDecoration(prefixIcon: Icon(Icons.search), hintText: "Search Unit or Resident", border: OutlineInputBorder())),
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

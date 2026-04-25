import 'package:flutter/material.dart';
import 'package:mycondo/data/models/shared/bill.dart';

class ResidentBillAddSheet extends StatefulWidget {
  const ResidentBillAddSheet({
    super.key,
    required this.onSubmit,
  });

  final Future<void> Function({
    required String billType,
    required DateTime dueDate,
    required List<Bill> bills,
  }) onSubmit;

  @override
  State<ResidentBillAddSheet> createState() => _ResidentBillAddSheetState();
}

class _ResidentBillAddSheetState extends State<ResidentBillAddSheet> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _nameControllers = [
    TextEditingController(),
  ];
  final List<TextEditingController> _amountControllers = [
    TextEditingController(),
  ];

  String _billType = 'One-Time Fee';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _isSaving = false;

  @override
  void dispose() {
    for (final controller in _nameControllers) {
      controller.dispose();
    }
    for (final controller in _amountControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked == null) return;
    setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final bills = <Bill>[];
    for (var index = 0; index < _nameControllers.length; index++) {
      bills.add(
        Bill(
          name: _nameControllers[index].text.trim(),
          amount: _toCentavos(_amountControllers[index].text),
        ),
      );
    }

    setState(() => _isSaving = true);
    try {
      await widget.onSubmit(
        billType: _billType,
        dueDate: _dueDate,
        bills: bills,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bill creation failed: $e')),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add Bill',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _billType,
                  decoration: const InputDecoration(
                    labelText: 'Bill type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'One-Time Fee',
                      child: Text('One-Time Fee'),
                    ),
                    DropdownMenuItem(
                      value: 'Monthly Bill',
                      child: Text('Monthly Bill'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _billType = value);
                  },
                ),
                const SizedBox(height: 10),
                const Text(
                  'This creates a separate applied bill record. If this is monthly, future edits to a monthly template should not change this bill.',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _pickDueDate,
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                    'Due ${_dueDate.month}/${_dueDate.day}/${_dueDate.year}',
                  ),
                ),
                const SizedBox(height: 16),
                for (var index = 0; index < _nameControllers.length; index++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _nameControllers[index],
                            decoration: const InputDecoration(
                              labelText: 'Item',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _amountControllers[index],
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Amount',
                              prefixText: 'PHP ',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final amount = _toCentavos(value ?? '');
                              if (amount <= 0) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                        IconButton(
                          onPressed: _nameControllers.length == 1
                              ? null
                              : () => _removeItem(index),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
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
                        : const Text('Add Bill'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addItem() {
    setState(() {
      _nameControllers.add(TextEditingController());
      _amountControllers.add(TextEditingController());
    });
  }

  void _removeItem(int index) {
    late final TextEditingController nameController;
    late final TextEditingController amountController;

    setState(() {
      nameController = _nameControllers.removeAt(index);
      amountController = _amountControllers.removeAt(index);
    });

    nameController.dispose();
    amountController.dispose();
  }

  int _toCentavos(String value) {
    final normalized = value.replaceAll(',', '').trim();
    final amount = double.tryParse(normalized);
    if (amount == null) return 0;
    return (amount * 100).round();
  }
}

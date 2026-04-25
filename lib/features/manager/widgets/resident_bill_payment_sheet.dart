import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mycondo/data/models/manager/resident_bill_group.dart';

class ResidentBillPaymentSheet extends StatefulWidget {
  const ResidentBillPaymentSheet({
    super.key,
    required this.bill,
    required this.onSubmit,
  });

  final ResidentBillGroup bill;
  final Future<void> Function(int amount) onSubmit;

  @override
  State<ResidentBillPaymentSheet> createState() =>
      _ResidentBillPaymentSheetState();
}

class _ResidentBillPaymentSheetState extends State<ResidentBillPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = _toCentavos(_amountController.text);
    setState(() => _isSaving = true);
    try {
      await widget.onSubmit(amount);
      if (!mounted) return;
      Navigator.pop(context);
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
                'Record Payment',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
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
                      : const Text('Save Payment'),
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

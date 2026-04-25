import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BillDetails extends StatelessWidget {
  BillDetails({
    super.key,
    required this.dueDate,
    required this.setSelectedBillType,
    required this.setDueDate,
  });

  final List<String> _billTypes = ["Monthly Bill", "One-Time Fee"];

  final DateTime dueDate;
  final ValueChanged<String?> setSelectedBillType;
  final ValueChanged<DateTime> setDueDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          decoration: _inputDecoration("Bill Type"),
          items: _billTypes
              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
              .toList(),
          onChanged: setSelectedBillType,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(color: Color(0xFFE6E2DD)),
              foregroundColor: const Color(0xFF1A1A1A),
            ),
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text("Due ${DateFormat('MMM d, yyyy').format(dueDate)}"),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: dueDate,
                firstDate: DateTime.now(),
                lastDate: DateTime(2030),
              );
              if (picked != null) setDueDate(picked);
            },
          ),
        ),
      ],
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
}

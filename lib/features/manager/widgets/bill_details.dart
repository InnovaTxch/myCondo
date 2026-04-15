
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BillDetails extends StatelessWidget {
  final List<String> _billTypes = ["Monthly Bill", "One-Time Fee"];

  final DateTime dueDate;
  final ValueChanged<String?> setSelectedBillType;
  final ValueChanged<DateTime> setDueDate;

  BillDetails({
    super.key,
    required this.dueDate,
    required this.setSelectedBillType,
    required this.setDueDate,
  });


  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "Bill Type", border: OutlineInputBorder()),
            items: _billTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (val) => setSelectedBillType(val),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
            icon: const Icon(Icons.calendar_month),
            label: Text(DateFormat('MMM dd').format(dueDate)),
            onPressed: () async {
              DateTime? picked = await showDatePicker(context: context, initialDate: dueDate, firstDate: DateTime.now(), lastDate: DateTime(2030));
              if (picked != null) setDueDate(picked);
            },
          ),
        ),
      ],
    );
  }
}



import 'package:flutter/material.dart';
import 'package:mycondo/theme/app_theme.dart';
import 'package:intl/intl.dart';

class BillDetails extends StatelessWidget {
  const BillDetails({
    super.key,
    required this.dueDate,
    required this.selectedBillType,
    required this.billTypes,
    required this.setSelectedBillType,
    required this.setDueDate,
  });

  final DateTime dueDate;
  final String? selectedBillType;
  final List<String> billTypes;
  final ValueChanged<String?> setSelectedBillType;
  final ValueChanged<DateTime> setDueDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          decoration: _inputDecoration("Bill Type"),
          initialValue: selectedBillType,
          items: billTypes
              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
              .toList(),
          onChanged: billTypes.length == 1 ? null : setSelectedBillType,
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
              foregroundColor: AppColors.darkText,
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
      fillColor: AppColors.creamWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}

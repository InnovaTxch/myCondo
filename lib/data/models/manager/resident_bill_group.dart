import 'package:mycondo/data/models/shared/bill.dart';

class ResidentBillGroup {
  const ResidentBillGroup({
    required this.id,
    required this.billType,
    required this.dueDate,
    required this.status,
    required this.bills,
  });

  final int id;
  final String billType;
  final DateTime dueDate;
  final String status;
  final List<Bill> bills;

  int get totalAmount {
    return bills.fold<int>(0, (total, bill) => total + bill.amount);
  }

  bool get isPaid => status == 'paid';

  factory ResidentBillGroup.fromMap({
    required Map<String, dynamic> map,
    required String billType,
  }) {
    final rows = (map['bills'] as List? ?? const [])
        .map((row) => row as Map<String, dynamic>)
        .toList();

    return ResidentBillGroup(
      id: map['id'] as int,
      billType: billType,
      dueDate: DateTime.parse(map['due_date'].toString()),
      status: (map['status'] ?? '').toString(),
      bills: rows
          .map(
            (row) => Bill(
              name: (row['name'] ?? '').toString(),
              amount: (row['amount'] as num).toInt(),
            ),
          )
          .toList(),
    );
  }
}

import 'bill.dart';

class Accountability {
  final int id;
  final String managerId;
  final String residentId;
  final String billType;
  final List<Bill> bills;
  final DateTime dueDate;
  final String status;

  Accountability({
    required this.id,
    required this.managerId,
    required this.residentId,
    required this.billType,
    required this.bills,
    required this.dueDate,
    required this.status,
  });
}
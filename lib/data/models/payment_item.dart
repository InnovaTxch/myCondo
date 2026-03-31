enum PaymentStatus { pending, approved, rejected }

class PaymentItem {
  final String residentName;
  final String room;
  final String amount;
  final String method;
  final String date;
  PaymentStatus status;

  PaymentItem({
    required this.residentName,
    required this.room,
    required this.amount,
    required this.method,
    required this.date,
    required this.status,
  });
}
enum PaymentStatus { pending, approved, rejected }

class PaymentItem {
  final int id;
  final String residentName;
  final String room;
  final int amount;
  final String date;
  final String billType;
  final int billId;
  final String? proofUrl;
  final String? remark;
  final String? rejectionReason;
  final PaymentStatus status;

  const PaymentItem({
    required this.id,
    required this.residentName,
    required this.room,
    required this.amount,
    required this.date,
    required this.billType,
    required this.billId,
    required this.status,
    this.proofUrl,
    this.remark,
    this.rejectionReason,
  });
}

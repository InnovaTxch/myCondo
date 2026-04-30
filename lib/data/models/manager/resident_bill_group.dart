import 'package:mycondo/data/models/shared/bill.dart';

class ResidentBillGroup {
  const ResidentBillGroup({
    required this.id,
    required this.billType,
    required this.dueDate,
    required this.status,
    required this.bills,
    required this.paidAmount,
    required this.payments,
  });

  final int id;
  final String billType;
  final DateTime dueDate;
  final String status;
  final List<Bill> bills;
  final int paidAmount;
  final List<BillPaymentAttempt> payments;

  int get totalAmount {
    return bills.fold<int>(0, (total, bill) => total + bill.amount);
  }

  bool get isPaid => status == 'paid';

  bool get isPartial => status == 'partial';

  BillPaymentAttempt? get pendingPayment {
    for (final payment in payments) {
      if (payment.status == 'pending') return payment;
    }
    return null;
  }

  BillPaymentAttempt? get latestRejectedPayment {
    for (final payment in payments) {
      if (payment.status == 'rejected') return payment;
    }
    return null;
  }

  int get outstandingAmount {
    final amount = totalAmount - paidAmount;
    return amount < 0 ? 0 : amount;
  }

  factory ResidentBillGroup.fromMap({
    required Map<String, dynamic> map,
    required String billType,
  }) {
    final rows = (map['bills'] as List? ?? const [])
        .map((row) => row as Map<String, dynamic>)
        .toList();
    final paymentRows = (map['payments'] as List? ?? const [])
        .map((row) => row as Map<String, dynamic>)
        .toList();

    final payments = paymentRows.map(BillPaymentAttempt.fromMap).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ResidentBillGroup(
      id: map['id'] as int,
      billType: billType,
      dueDate: DateTime.parse(map['due_date'].toString()),
      status: (map['status'] ?? '').toString(),
      paidAmount: payments.fold<int>(0, (total, payment) {
        if (payment.status != 'completed') return total;
        return total + payment.amount;
      }),
      payments: payments,
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

class BillPaymentAttempt {
  const BillPaymentAttempt({
    required this.id,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.proofUrl,
    this.remark,
    this.rejectionReason,
  });

  final int id;
  final int amount;
  final String status;
  final DateTime createdAt;
  final String? proofUrl;
  final String? remark;
  final String? rejectionReason;

  factory BillPaymentAttempt.fromMap(Map<String, dynamic> map) {
    final createdAt = map['created_at'] == null
        ? DateTime.fromMillisecondsSinceEpoch(0)
        : DateTime.parse(map['created_at'].toString());

    return BillPaymentAttempt(
      id: (map['id'] as num?)?.toInt() ?? 0,
      amount: (map['amount'] as num).toInt(),
      status: (map['status'] ?? '').toString(),
      createdAt: createdAt,
      proofUrl: map['proof_url']?.toString(),
      remark: map['remark']?.toString(),
      rejectionReason: map['rejection_reason']?.toString(),
    );
  }
}

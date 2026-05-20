class UnitMonthlyChargeTemplate {
  const UnitMonthlyChargeTemplate({
    required this.id,
    required this.unitId,
    required this.name,
    required this.amount,
  });

  final int id;
  final int unitId;
  final String name;
  final int amount;

  factory UnitMonthlyChargeTemplate.fromMap(Map<String, dynamic> map) {
    return UnitMonthlyChargeTemplate(
      id: (map['id'] as num).toInt(),
      unitId: (map['unit_id'] as num).toInt(),
      name: (map['name'] ?? '').toString().trim(),
      amount: (map['amount'] as num).toInt(),
    );
  }
}

class UnitPaymentEntry {
  const UnitPaymentEntry({
    required this.residentName,
    required this.paidAt,
    required this.amount,
  });

  final String residentName;
  final DateTime paidAt;
  final int amount;
}

class UnitPaymentPayer {
  const UnitPaymentPayer({required this.id, required this.name});

  final String id;
  final String name;
}

class UnitLedgerCharge {
  const UnitLedgerCharge({
    required this.name,
    required this.amount,
    required this.isOneTime,
  });

  final String name;
  final int amount;
  final bool isOneTime;
}

class UnitMonthlyLedger {
  const UnitMonthlyLedger({
    required this.month,
    required this.dueDate,
    required this.hasAssignedBill,
    required this.totalAmount,
    required this.paidAmount,
    required this.pendingAmount,
    required this.remainingAmount,
    required this.status,
    required this.charges,
    required this.payments,
  });

  final DateTime month;
  final DateTime dueDate;
  final bool hasAssignedBill;
  final int totalAmount;
  final int paidAmount;
  final int pendingAmount;
  final int remainingAmount;
  final String status;
  final List<UnitLedgerCharge> charges;
  final List<UnitPaymentEntry> payments;

  bool get hasPendingPayment => pendingAmount > 0;
}

class UnitBillPaymentSummary {
  const UnitBillPaymentSummary({
    required this.unitId,
    required this.month,
    required this.dueDate,
    required this.hasAssignedBill,
    required this.totalAmount,
    required this.paidAmount,
  });

  final int unitId;
  final DateTime month;
  final DateTime dueDate;
  final bool hasAssignedBill;
  final int totalAmount;
  final int paidAmount;

  int get remainingAmount => (totalAmount - paidAmount).clamp(0, totalAmount);
  bool get hasPaymentActivity => paidAmount > 0;
  bool get isFullyPaid =>
      hasAssignedBill && totalAmount > 0 && paidAmount >= totalAmount;

  double get paymentProgress {
    if (!hasAssignedBill || totalAmount <= 0) return 0;
    return (paidAmount / totalAmount).clamp(0, 1).toDouble();
  }

  bool get isOverdue {
    if (!hasAssignedBill || isFullyPaid || !hasPaymentActivity) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return dueDay.isBefore(today);
  }

  bool get isNearDue {
    if (!hasAssignedBill || isFullyPaid || !hasPaymentActivity || isOverdue) {
      return false;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return dueDay.difference(today).inDays <= 3;
  }

  factory UnitBillPaymentSummary.empty({
    required int unitId,
    required DateTime month,
  }) {
    final dueDate = DateTime(
      month.year,
      month.month + 1,
      1,
    ).subtract(const Duration(days: 1));
    return UnitBillPaymentSummary(
      unitId: unitId,
      month: DateTime(month.year, month.month, 1),
      dueDate: dueDate,
      hasAssignedBill: false,
      totalAmount: 0,
      paidAmount: 0,
    );
  }
}

enum ApplyChargeChangeMonth { currentMonth, nextMonth }

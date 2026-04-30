import 'package:mycondo/data/models/payment_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentApprovalRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<PaymentItem>> getPayments(PaymentStatus status) async {
    return _getPaymentsForStatuses([_toDatabaseStatus(status)]);
  }

  Future<List<PaymentItem>> getProcessedPayments() async {
    return _getPaymentsForStatuses(['completed', 'rejected']);
  }

  Future<List<PaymentItem>> _getPaymentsForStatuses(
    List<String> statuses,
  ) async {
    final manager = await _requireManagerContext();
    final residentIds = await _getResidentIdsForCondo(manager.condoId);
    if (residentIds.isEmpty) return [];

    final data = await _supabase
        .from('payments')
        .select('''
          id,
          amount,
          status,
          proof_url,
          remark,
          rejection_reason,
          created_at,
          monthly_bill_id,
          one_time_fee_id,
          paid_by,
          monthly_bills!payments_monthly_bill_id_fkey(id, due_date),
          one_time_fees!payments_one_time_fee_id_fkey(id, due_date)
        ''')
        .inFilter('paid_by', residentIds)
        .inFilter('status', statuses)
        .order('created_at', ascending: false);

    final profiles = await _getProfilesForPayments(data as List);
    return (data as List)
        .map((row) => _paymentFromMap(
              row as Map<String, dynamic>,
              profiles,
            ))
        .toList();
  }

  Future<void> approvePayment(PaymentItem payment) async {
    final manager = await _requireManagerContext();

    await _supabase.from('payments').update({
      'status': 'completed',
      'validated_by': manager.managerId,
      'rejection_reason': null,
    }).eq('id', payment.id);

    final bill = await _getBillForPayment(payment);
    final paidAmount = await _getCompletedPaidAmount(payment);
    final nextStatus = paidAmount >= bill.totalAmount ? 'paid' : 'partial';
    final table = payment.billType == 'Monthly Bill'
        ? 'monthly_bills'
        : 'one_time_fees';

    await _supabase.from(table).update({'status': nextStatus}).eq(
      'id',
      payment.billId,
    );
  }

  Future<void> rejectPayment({
    required PaymentItem payment,
    required String reason,
  }) async {
    final manager = await _requireManagerContext();
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      throw Exception('A rejection reason is required.');
    }

    await _supabase.from('payments').update({
      'status': 'rejected',
      'validated_by': manager.managerId,
      'rejection_reason': trimmed,
    }).eq('id', payment.id);
  }

  String _toDatabaseStatus(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.approved:
        return 'completed';
      case PaymentStatus.rejected:
        return 'rejected';
    }
  }

  PaymentItem _paymentFromMap(
    Map<String, dynamic> map,
    Map<String, String> profiles,
  ) {
    final monthlyBill = map['monthly_bills'] as Map<String, dynamic>?;
    final oneTimeFee = map['one_time_fees'] as Map<String, dynamic>?;
    final billType = monthlyBill != null ? 'Monthly Bill' : 'One-Time Fee';
    final bill = monthlyBill ?? oneTimeFee ?? const <String, dynamic>{};
    final paidBy = (map['paid_by'] ?? '').toString();
    final name = profiles[paidBy] ?? '';

    return PaymentItem(
      id: (map['id'] as num).toInt(),
      residentName: name.isEmpty ? 'Resident' : name,
      room: billType,
      amount: (map['amount'] as num).toInt(),
      date: (map['created_at'] ?? '').toString(),
      billType: billType,
      billId: (bill['id'] as num?)?.toInt() ?? 0,
      proofUrl: map['proof_url']?.toString(),
      remark: map['remark']?.toString(),
      rejectionReason: map['rejection_reason']?.toString(),
      status: _fromDatabaseStatus((map['status'] ?? '').toString()),
    );
  }

  PaymentStatus _fromDatabaseStatus(String status) {
    switch (status) {
      case 'completed':
        return PaymentStatus.approved;
      case 'rejected':
        return PaymentStatus.rejected;
      default:
        return PaymentStatus.pending;
    }
  }

  Future<List<String>> _getResidentIdsForCondo(int condoId) async {
    final units = await _supabase
        .from('units')
        .select('id')
        .eq('condo_id', condoId);

    final unitIds = (units as List)
        .map((row) => (row as Map<String, dynamic>)['id'])
        .toList();
    if (unitIds.isEmpty) return [];

    final residents = await _supabase
        .from('residents')
        .select('id')
        .inFilter('unit_id', unitIds);

    return (residents as List)
        .map((row) => (row as Map<String, dynamic>)['id'].toString())
        .toList();
  }

  Future<Map<String, String>> _getProfilesForPayments(List<dynamic> rows) async {
    final ids = rows
        .map((row) => (row as Map<String, dynamic>)['paid_by']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (ids.isEmpty) return {};

    final profiles = await _supabase
        .from('profiles')
        .select('id, first_name, last_name')
        .inFilter('id', ids);

    return {
      for (final row in profiles as List)
        (row as Map<String, dynamic>)['id'].toString(): [
          (row['first_name'] ?? '').toString().trim(),
          (row['last_name'] ?? '').toString().trim(),
        ].where((part) => part.isNotEmpty).join(' '),
    };
  }

  Future<_BillTotals> _getBillForPayment(PaymentItem payment) async {
    final foreignKey =
        payment.billType == 'Monthly Bill' ? 'monthly_bill_id' : 'one_time_fee_id';

    final rows = await _supabase
        .from('bills')
        .select('amount')
        .eq(foreignKey, payment.billId);

    final total = (rows as List).fold<int>(0, (sum, row) {
      return sum + ((row as Map<String, dynamic>)['amount'] as num).toInt();
    });

    return _BillTotals(totalAmount: total);
  }

  Future<int> _getCompletedPaidAmount(PaymentItem payment) async {
    final foreignKey =
        payment.billType == 'Monthly Bill' ? 'monthly_bill_id' : 'one_time_fee_id';

    final rows = await _supabase
        .from('payments')
        .select('amount')
        .eq(foreignKey, payment.billId)
        .eq('status', 'completed');

    return (rows as List).fold<int>(0, (sum, row) {
      return sum + ((row as Map<String, dynamic>)['amount'] as num).toInt();
    });
  }

  Future<_ManagerContext> _requireManagerContext() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No authenticated manager user found.');
    }

    final manager = await _supabase
        .from('managers')
        .select('id, condo_id')
        .eq('id', userId)
        .single();

    final condoIdValue = manager['condo_id'];
    return _ManagerContext(
      managerId: (manager['id'] as String?) ?? userId,
      condoId: condoIdValue is int
          ? condoIdValue
          : int.parse(condoIdValue.toString()),
    );
  }
}

class _ManagerContext {
  const _ManagerContext({
    required this.managerId,
    required this.condoId,
  });

  final String managerId;
  final int condoId;
}

class _BillTotals {
  const _BillTotals({required this.totalAmount});

  final int totalAmount;
}

import 'package:mycondo/data/models/manager/resident_bill_group.dart';
import 'package:mycondo/data/models/shared/bill.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResidentBillRepository {
  ResidentBillRepository._();

  static final ResidentBillRepository instance = ResidentBillRepository._();

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<ResidentBillGroup>> getBillsForResident(String residentId) async {
    final monthlyRows = await _supabase
        .from('monthly_bills')
        .select(
          'id, due_date, status, '
          'bills!bills_monthly_bill_id_fkey(name, amount), '
          'payments!payments_monthly_bill_id_fkey(amount, status)',
        )
        .eq('received_by', residentId);

    final oneTimeRows = await _supabase
        .from('one_time_fees')
        .select(
          'id, due_date, status, '
          'bills!bills_one_time_fee_id_fkey(name, amount), '
          'payments!payments_one_time_fee_id_fkey(amount, status)',
        )
        .eq('received_by', residentId);

    final bills = <ResidentBillGroup>[
      ...(monthlyRows as List).map(
        (row) => ResidentBillGroup.fromMap(
          map: row as Map<String, dynamic>,
          billType: 'Monthly Bill',
        ),
      ),
      ...(oneTimeRows as List).map(
        (row) => ResidentBillGroup.fromMap(
          map: row as Map<String, dynamic>,
          billType: 'One-Time Fee',
        ),
      ),
    ];

    bills.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return bills;
  }

  Future<void> deleteBill(ResidentBillGroup bill) async {
    if (bill.billType == 'Monthly Bill') {
      await _supabase.from('payments').delete().eq('monthly_bill_id', bill.id);
      await _supabase.from('bills').delete().eq('monthly_bill_id', bill.id);
      await _supabase.from('monthly_bills').delete().eq('id', bill.id);
      return;
    }

    await _supabase.from('payments').delete().eq('one_time_fee_id', bill.id);
    await _supabase.from('bills').delete().eq('one_time_fee_id', bill.id);
    await _supabase.from('one_time_fees').delete().eq('id', bill.id);
  }

  Future<void> recordPayment({
    required ResidentBillGroup bill,
    required String residentId,
    required int amount,
  }) async {
    final managerId = _supabase.auth.currentUser?.id;
    if (managerId == null) throw Exception('User not authenticated');
    if (amount <= 0) throw Exception('Payment must be greater than zero.');
    if (amount > bill.outstandingAmount) {
      throw Exception('Payment cannot exceed the outstanding bill amount.');
    }

    final nextPaidAmount = bill.paidAmount + amount;
    final nextStatus = nextPaidAmount >= bill.totalAmount ? 'paid' : 'partial';
    final payment = <String, dynamic>{
      'paid_by': residentId,
      'validated_by': managerId,
      'amount': amount,
      'status': 'completed',
    };

    if (bill.billType == 'Monthly Bill') {
      payment['monthly_bill_id'] = bill.id;
      payment['one_time_fee_id'] = null;
      await _supabase.from('payments').insert(payment);
      await _supabase
          .from('monthly_bills')
          .update({'status': nextStatus}).eq('id', bill.id);
      return;
    }

    payment['monthly_bill_id'] = null;
    payment['one_time_fee_id'] = bill.id;
    await _supabase.from('payments').insert(payment);
    await _supabase
        .from('one_time_fees')
        .update({'status': nextStatus}).eq('id', bill.id);
  }

  Future<void> addBill({
    required String residentId,
    required String billType,
    required DateTime dueDate,
    required List<Bill> bills,
  }) async {
    final managerId = _supabase.auth.currentUser?.id;
    if (managerId == null) throw Exception('User not authenticated');

    final parentTable =
        billType == 'Monthly Bill' ? 'monthly_bills' : 'one_time_fees';
    final foreignKey =
        billType == 'Monthly Bill' ? 'monthly_bill_id' : 'one_time_fee_id';

    final parent = await _supabase.from(parentTable).insert({
      'received_by': residentId,
      'posted_by': managerId,
      'due_date': dueDate.toIso8601String(),
      'status': 'unpaid',
    }).select('id').single();

    final parentId = parent['id'] as int;
    await _supabase.from('bills').insert(
          bills
              .map(
                (bill) => {
                  foreignKey: parentId,
                  'name': bill.name,
                  'amount': bill.amount,
                },
              )
              .toList(),
        );
  }
}

import 'package:mycondo/data/models/manager/resident_bill_group.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResidentBillRepository {
  ResidentBillRepository._();

  static final ResidentBillRepository instance = ResidentBillRepository._();

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<ResidentBillGroup>> getBillsForResident(String residentId) async {
    final monthlyRows = await _supabase
        .from('monthly_bills')
        .select(
          'id, due_date, status, bills!bills_monthly_bill_id_fkey(name, amount)',
        )
        .eq('received_by', residentId);

    final oneTimeRows = await _supabase
        .from('one_time_fees')
        .select(
          'id, due_date, status, bills!bills_one_time_fee_id_fkey(name, amount)',
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
}

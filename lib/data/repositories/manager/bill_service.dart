import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mycondo/data/models/shared/bill.dart';

class BillService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> generateAndSendBills({
    required String billType,
    required List<String> residentIds,
    required DateTime dueDate,
    required List<Bill> bills,
    required bool isAccountabilityShared,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception("User not authenticated");

    final String accRepository = billType == "Monthly Bill" ? "monthly_bills" : "one_time_fees";
    final String foreignKey = billType == "Monthly Bill" ? "monthly_bill_id" : "one_time_fee_id";

    for (String residentId in residentIds) {
      final response = await _supabase.from(accRepository).insert({
        'received_by': residentId,
        'posted_by': userId,
        'due_date': dueDate.toIso8601String(),
      }).select('id').single();

      final int accId = response['id'];
      final List<Map<String, dynamic>> itemsToInsert = bills.map((bill) {
        final finalAmount = isAccountabilityShared 
            ? (bill.amount / residentIds.length).round() 
            : bill.amount;

        return {
          foreignKey: accId,
          'name': bill.name,
          'amount': finalAmount,
        };
      }).toList();

      await _supabase.from('bills').insert(itemsToInsert);
    }
  }
}
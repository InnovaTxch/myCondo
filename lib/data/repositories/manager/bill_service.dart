import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mycondo/data/models/shared/bill.dart';
import 'package:mycondo/data/repositories/auth/profile_identity_service.dart';

class BillService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ProfileIdentityService _identity = ProfileIdentityService();

  Future<void> generateAndSendBills({
    required String billType,
    required List<String> residentIds,
    required DateTime dueDate,
    required List<Bill> bills,
    required bool isAccountabilityShared,
  }) async {
    final manager = await _identity.requireCurrentProfile(
      missingMessage: 'No manager profile is linked to this signed-in user.',
    );

    final String accRepository = billType == "Monthly Bill" ? "monthly_bills" : "one_time_fees";
    final String foreignKey = billType == "Monthly Bill" ? "monthly_bill_id" : "one_time_fee_id";

    for (String residentId in residentIds) {
      final response = await _supabase.from(accRepository).insert({
        'received_by': residentId,
        'posted_by': manager.id,
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

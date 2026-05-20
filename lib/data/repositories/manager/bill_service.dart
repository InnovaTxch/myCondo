import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mycondo/data/models/shared/bill.dart';
import 'package:mycondo/data/repositories/auth/profile_identity_service.dart';

enum BillRecipientMode { resident, unit }

class BillService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ProfileIdentityService _identity = ProfileIdentityService();

  Future<void> generateAndSendBills({
    required String billType,
    required DateTime dueDate,
    required List<Bill> bills,
    required bool isAccountabilityShared,
    required BillRecipientMode recipientMode,
    List<String> residentIds = const <String>[],
    List<int> unitIds = const <int>[],
  }) async {
    final manager = await _identity.requireCurrentProfile(
      missingMessage: 'No manager profile is linked to this signed-in user.',
    );

    final String accRepository = billType == "Monthly Bill"
        ? "monthly_bills"
        : "one_time_fees";
    final String foreignKey = billType == "Monthly Bill"
        ? "monthly_bill_id"
        : "one_time_fee_id";

    final targets = recipientMode == BillRecipientMode.unit
        ? unitIds.toSet().toList()
        : residentIds.toSet().toList();

    if (targets.isEmpty) {
      throw Exception('Select at least one recipient.');
    }

    for (final target in targets) {
      final payload = <String, dynamic>{
        'posted_by': manager.id,
        'due_date': dueDate.toIso8601String(),
      };

      if (recipientMode == BillRecipientMode.unit) {
        payload['target_unit_id'] = target;
      } else {
        payload['received_by'] = target;
      }

      final response = await _supabase
          .from(accRepository)
          .insert({...payload})
          .select('id')
          .single();

      final int accId = response['id'];
      final List<Map<String, dynamic>> itemsToInsert = bills.map((bill) {
        final finalAmount = isAccountabilityShared
            ? (bill.amount / targets.length).round()
            : bill.amount;

        return {foreignKey: accId, 'name': bill.name, 'amount': finalAmount};
      }).toList();

      await _supabase.from('bills').insert(itemsToInsert);
    }
  }
}

import 'package:mycondo/data/models/resident.dart';
import 'package:mycondo/data/models/unit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResidentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Unit>?> fetchUnitsForManager() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final condoData = await _supabase
          .from('managers')
          .select('condo_id')
          .eq('id', userId)
          .single();

      final int condoId = condoData['condo_id'];
      final List<dynamic> data = await _supabase
          .from('units')
          .select('id, name, residents(id, profiles(first_name))')
          .eq('condo_id', condoId);

      return data.map((unitRow) {
        final List<dynamic> residentRows = unitRow['residents'] ?? [];

        return Unit(
          id: unitRow['id'] as int,
          name: unitRow['name'] as String,
          members: residentRows
              .map(
                (resRow) => Resident(
                  id: resRow['id'] as String,
                  name: resRow['profiles']['first_name'] as String,
                  unitName: unitRow['name'] as String,
                ),
              )
              .toList(),
        );
      }).toList();
    } catch (e) {
      print("Error fetching units: $e");
      return [];
    }
  }
}

import 'package:mycondo/data/models/manager/resident_profile.dart';
import 'package:mycondo/data/repositories/auth/profile_identity_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CondoUnitRepository {
  CondoUnitRepository._();

  static final CondoUnitRepository instance = CondoUnitRepository._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final ProfileIdentityService _identity = ProfileIdentityService();

  Future<List<UnitOption>> getUnits() async {
    final condoId = await _requireManagerCondoId();
    final unitsData = await _supabase
        .from('units')
        .select('id, name, capacity')
        .eq('condo_id', condoId)
        .order('name');

    final units = (unitsData as List)
        .map(
          (row) => UnitOption(
            id: row['id'] as int,
            name: (row['name'] ?? '').toString(),
            capacity: row['capacity'] as int?,
          ),
        )
        .toList();

    if (units.isEmpty) return units;

    final unitIds = units.map((unit) => unit.id).toList();
    final residentsData = await _supabase
        .from('residents')
        .select('unit_id')
        .inFilter('unit_id', unitIds)
        .eq('status', 'active');

    final occupancy = <int, int>{};
    for (final row in residentsData as List) {
      final unitId = row['unit_id'] as int?;
      if (unitId == null) continue;
      occupancy[unitId] = (occupancy[unitId] ?? 0) + 1;
    }

    return units
        .map(
          (unit) => UnitOption(
            id: unit.id,
            name: unit.name,
            capacity: unit.capacity,
            occupied: occupancy[unit.id] ?? 0,
          ),
        )
        .toList();
  }

  Future<void> addUnit({
    required String name,
    required int capacity,
  }) async {
    final condoId = await _requireManagerCondoId();
    await _supabase.from('units').insert({
      'name': name.trim(),
      'capacity': capacity,
      'condo_id': condoId,
    });
  }

  Future<void> updateUnit({
    required int id,
    required String name,
    required int capacity,
  }) async {
    final condoId = await _requireManagerCondoId();
    final units = await getUnits();
    final unit = units.firstWhere((unit) => unit.id == id);

    if (capacity < unit.occupied) {
      throw StateError(
        'Capacity cannot be lower than the ${unit.occupied} current tenants.',
      );
    }

    await _supabase.from('units').update({
      'name': name.trim(),
      'capacity': capacity,
    }).eq('id', id).eq('condo_id', condoId);
  }

  Future<void> deleteUnit(UnitOption unit) async {
    final condoId = await _requireManagerCondoId();
    if (unit.occupied > 0) {
      throw StateError('Move or remove tenants before deleting this unit.');
    }

    await _supabase.from('units').delete().eq('id', unit.id).eq(
          'condo_id',
          condoId,
        );
  }

  Future<int> _requireManagerCondoId() async {
    final profile = await _identity.requireCurrentProfile(
      missingMessage: 'No manager profile is linked to this signed-in user.',
    );

    final manager = await _supabase
        .from('managers')
        .select('condo_id')
        .eq('id', profile.id)
        .single();

    final value = manager['condo_id'];
    return value is int ? value : int.parse(value.toString());
  }
}

import 'package:flutter/foundation.dart';
import 'package:mycondo/data/models/manager/resident_profile.dart';
import 'package:mycondo/data/repositories/auth/profile_identity_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResidentRepository {
  ResidentRepository._();

  static final ResidentRepository instance = ResidentRepository._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final ProfileIdentityService _identity = ProfileIdentityService();

  final ValueNotifier<List<ResidentProfile>> residentsNotifier =
      ValueNotifier<List<ResidentProfile>>(<ResidentProfile>[]);
  final ValueNotifier<List<UnitResidentGroup>> unitGroupsNotifier =
      ValueNotifier<List<UnitResidentGroup>>(<UnitResidentGroup>[]);

  Future<List<ResidentProfile>> getResidents({String query = ''}) async {
    final residents = List<ResidentProfile>.from(residentsNotifier.value)
      ..sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return residents;

    return residents
        .where((resident) => resident.matchesQuery(trimmed))
        .toList();
  }

  Future<void> refreshResidents() async {
    final context = await _requireManagerContext();
    final unitsData = await _supabase
        .from('units')
        .select('id, name, capacity')
        .eq('condo_id', context.condoId);

    final units = (unitsData as List)
        .map(
          (row) => UnitOption(
            id: row['id'] as int,
            name: (row['name'] ?? '').toString(),
            capacity: row['capacity'] as int?,
          ),
        )
        .toList();

    if (units.isEmpty) {
      residentsNotifier.value = <ResidentProfile>[];
      unitGroupsNotifier.value = <UnitResidentGroup>[];
      return;
    }

    final unitById = {for (final unit in units) unit.id: unit};
    final unitIds = units.map((unit) => unit.id).toList();

    final residentsData = await _supabase
        .from('residents')
        .select('id, unit_id, status, code')
        .inFilter('unit_id', unitIds)
        .eq('status', 'active');

    final residentRows = (residentsData as List)
        .map((row) => row as Map<String, dynamic>)
        .toList();

    if (residentRows.isEmpty) {
      residentsNotifier.value = <ResidentProfile>[];
      unitGroupsNotifier.value = units
          .map((unit) => UnitResidentGroup(unit: unit, residents: const []))
          .toList();
      return;
    }

    final residentIds = residentRows
        .map((row) => row['id'].toString())
        .toList();

    final profilesData = await _supabase
        .from('profiles')
        .select('id, first_name, last_name')
        .inFilter('id', residentIds);

    final profileById = <String, Map<String, dynamic>>{};
    for (final row in (profilesData as List)) {
      final profile = row as Map<String, dynamic>;
      profileById[profile['id'].toString()] = profile;
    }

    final residents = residentRows.map((row) {
      final residentId = row['id'].toString();
      final profile = profileById[residentId] ?? const <String, dynamic>{};
      final unitId = row['unit_id'] as int?;
      final unit = unitId == null ? null : unitById[unitId];

      final firstName = (profile['first_name'] ?? '').toString().trim();
      final lastName = (profile['last_name'] ?? '').toString().trim();
      final name = '$firstName $lastName'.trim();

      return ResidentProfile(
        id: residentId,
        name: name.isEmpty ? 'Unnamed Resident' : name,
        unit: unit?.name ?? 'Unknown Unit',
        unitId: unitId,
        status: row['status']?.toString(),
        condoCode: context.condoCode,
        residentCode: row['code']?.toString(),
      );
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    residentsNotifier.value = residents;
    unitGroupsNotifier.value = _buildUnitGroups(units, residents);
  }

  Future<ResidentProfile?> getResidentById(String residentId) async {
    try {
      return residentsNotifier.value.firstWhere((r) => r.id == residentId);
    } catch (_) {
      return null;
    }
  }

  Future<List<UnitOption>> getUnitOptions() async {
    final context = await _requireManagerContext();
    final unitsData = await _supabase
        .from('units')
        .select('id, name, capacity')
        .eq('condo_id', context.condoId)
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

  Future<ResidentProfile> addResident(ResidentUpsertInput input) async {
    final context = await _requireManagerContext();

    final created = await _supabase.rpc(
      'create_resident_profile',
      params: {
        'p_first_name': input.firstName.trim(),
        'p_last_name': input.lastName.trim(),
        'p_unit_id': input.unitId,
      },
    );

    final createdRow = (created as List).isNotEmpty ? created.first as Map : null;
    final profileId = (createdRow?['resident_id'] ?? '').toString();
    final code = (createdRow?['resident_code'] ?? '').toString();

    await refreshResidents();
    final resident = (await getResidentById(profileId)) ??
        ResidentProfile(
          id: profileId,
          name: input.name.trim(),
          unit: 'Selected Unit',
          unitId: input.unitId,
          status: 'active',
        );

    return resident.copyWith(
      condoCode: context.condoCode,
      residentCode: code,
    );
  }

  Future<void> updateResident(
    String residentId,
    ResidentUpsertInput input,
  ) async {
    await _supabase.rpc(
      'update_resident_profile',
      params: {
        'p_resident_id': residentId,
        'p_full_name': input.name,
        'p_unit_id': input.unitId,
      },
    );

    await refreshResidents();
  }

  Future<void> deleteResident(String residentId) async {
    await _supabase.rpc(
      'vacate_resident',
      params: {'p_resident_id': residentId},
    );
    await refreshResidents();
  }

  List<UnitResidentGroup> _buildUnitGroups(
    List<UnitOption> units,
    List<ResidentProfile> residents,
  ) {
    return units.map((unit) {
      final unitResidents = residents
          .where((resident) => resident.unitId == unit.id)
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      return UnitResidentGroup(
        unit: UnitOption(
          id: unit.id,
          name: unit.name,
          capacity: unit.capacity,
          occupied: unitResidents.length,
        ),
        residents: unitResidents,
      );
    }).toList()
      ..sort(
        (a, b) => a.unit.name.toLowerCase().compareTo(b.unit.name.toLowerCase()),
      );
  }

  Future<_ManagerContext> _requireManagerContext() async {
    final profile = await _identity.requireCurrentProfile(
      missingMessage: 'No manager profile is linked to this signed-in user.',
    );

    final manager = await _supabase
        .from('managers')
        .select('id, condo_id, condos(code)')
        .eq('id', profile.id)
        .single();

    final condoIdValue = manager['condo_id'];
    final condoId = condoIdValue is int
        ? condoIdValue
        : int.parse(condoIdValue.toString());

    return _ManagerContext(
      condoId: condoId,
      condoCode: (manager['condos']?['code'] ?? '').toString(),
    );
  }


}

class _ManagerContext {
  const _ManagerContext({
    required this.condoId,
    required this.condoCode,
  });

  final int condoId;
  final String condoCode;
}

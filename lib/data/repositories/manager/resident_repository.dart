import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:mycondo/data/models/manager/resident_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResidentRepository {
  ResidentRepository._();

  static final ResidentRepository instance = ResidentRepository._();

  final SupabaseClient _supabase = Supabase.instance.client;

  final ValueNotifier<List<ResidentProfile>> residentsNotifier =
      ValueNotifier<List<ResidentProfile>>(<ResidentProfile>[]);

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
        .select('id, name')
        .eq('condo_id', context.condoId);

    final units = (unitsData as List)
        .map(
          (row) => UnitOption(
            id: row['id'] as int,
            name: (row['name'] ?? '').toString(),
          ),
        )
        .toList();

    if (units.isEmpty) {
      residentsNotifier.value = <ResidentProfile>[];
      return;
    }

    final unitById = {for (final unit in units) unit.id: unit};
    final unitIds = units.map((unit) => unit.id).toList();

    final residentsData = await _supabase
        .from('residents')
        .select('id, unit_id, status')
        .inFilter('unit_id', unitIds)
        .eq('status', 'active');

    final residentRows = (residentsData as List)
        .map((row) => row as Map<String, dynamic>)
        .toList();

    if (residentRows.isEmpty) {
      residentsNotifier.value = <ResidentProfile>[];
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
      );
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    residentsNotifier.value = residents;
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
    final data = await _supabase
        .from('units')
        .select('id, name, capacity')
        .eq('condo_id', context.condoId)
        .order('name');

    return (data as List)
        .map(
          (row) => UnitOption(
            id: row['id'] as int,
            name: (row['name'] ?? '').toString(),
            capacity: row['capacity'] as int?,
          ),
        )
        .toList();
  }

  Future<void> addResident(ResidentUpsertInput input) async {
    final context = await _requireManagerContext();
    await _assertUnitBelongsToCondo(
      unitId: input.unitId,
      condoId: context.condoId,
    );

    final residentId = _generateUuidV4();
    final (firstName, lastName) = _splitName(input.name);
    final now = DateTime.now().toUtc().toIso8601String();

    await _supabase.from('profiles').upsert({
      'id': residentId,
      'first_name': firstName,
      'last_name': lastName,
      'role': 'resident',
    });

    await _supabase.from('residents').upsert({
      'id': residentId,
      'unit_id': input.unitId,
      'status': 'active',
      'requested_at': now,
      'approved_at': now,
      'left_at': null,
    });

    await refreshResidents();
  }

  Future<void> updateResident(String residentId, ResidentUpsertInput input) async {
    final context = await _requireManagerContext();
    await _assertUnitBelongsToCondo(
      unitId: input.unitId,
      condoId: context.condoId,
    );

    final (firstName, lastName) = _splitName(input.name);

    await _supabase.from('profiles').update({
      'first_name': firstName,
      'last_name': lastName,
      'role': 'resident',
    }).eq('id', residentId);

    await _supabase.from('residents').update({
      'unit_id': input.unitId,
      'status': 'active',
      'left_at': null,
    }).eq('id', residentId);

    await refreshResidents();
  }

  Future<void> deleteResident(String residentId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _supabase.from('residents').update({
      'status': 'left',
      'left_at': now,
    }).eq('id', residentId);

    await refreshResidents();
  }

  Future<void> _assertUnitBelongsToCondo({
    required int unitId,
    required int condoId,
  }) async {
    final unit = await _supabase
        .from('units')
        .select('id')
        .eq('id', unitId)
        .eq('condo_id', condoId)
        .maybeSingle();

    if (unit == null) {
      throw StateError('Selected unit does not belong to your condo.');
    }
  }

  Future<_ManagerContext> _requireManagerContext() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No authenticated manager found.');
    }

    final manager = await _supabase
        .from('managers')
        .select('id, condo_id')
        .eq('id', userId)
        .single();

    final condoIdValue = manager['condo_id'];
    final condoId = condoIdValue is int
        ? condoIdValue
        : int.parse(condoIdValue.toString());

    return _ManagerContext(
      condoId: condoId,
    );
  }

  (String, String) _splitName(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return ('', '');
    if (parts.length == 1) return (parts.first, '');
    return (parts.first, parts.sublist(1).join(' '));
  }

  String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));

    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hex(int value) => value.toRadixString(16).padLeft(2, '0');
    final b = bytes.map(hex).toList();
    return '${b[0]}${b[1]}${b[2]}${b[3]}-'
        '${b[4]}${b[5]}-'
        '${b[6]}${b[7]}-'
        '${b[8]}${b[9]}-'
        '${b[10]}${b[11]}${b[12]}${b[13]}${b[14]}${b[15]}';
  }
}

class _ManagerContext {
  const _ManagerContext({
    required this.condoId,
  });

  final int condoId;
}

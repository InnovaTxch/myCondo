import 'package:mycondo/data/repositories/auth/profile_identity_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MaintenanceRequestService {
  MaintenanceRequestService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;
  final ProfileIdentityService _identity = ProfileIdentityService();

  Future<MaintenanceResidentDetails> fetchResidentDetails() async {
    final context = await _requireResidentContext();
    return MaintenanceResidentDetails(
      firstName: context.firstName,
      lastName: context.lastName,
      roomNumber: context.unitName,
    );
  }

  Future<void> submitRequest(MaintenanceRequestInput input) async {
    final context = await _requireResidentContext();

    await _supabase.from('maintenance_requests').insert({
      'resident_id': context.residentId,
      'unit_id': context.unitId,
      'condo_id': context.condoId,
      'reporter_first_name': input.firstName.trim(),
      'reporter_last_name': input.lastName.trim(),
      'room_number': input.roomNumber.trim(),
      'priority': input.priority.toLowerCase(),
      'problem_type': input.problemType,
      'description': input.description.trim(),
      'status': 'pending',
    });
  }

  Future<List<MaintenanceRequestRecord>> fetchMyRequests({
    String? status,
  }) async {
    final profileIdentity = await _identity.requireCurrentProfile(
      missingMessage: 'No resident profile is linked to this signed-in user.',
    );

    var query = _supabase
        .from('maintenance_requests')
        .select(
          'id, created_at, priority, problem_type, description, '
          'status, manager_notes, resolved_at',
        )
        .eq('resident_id', profileIdentity.id);

    if (status != null && status != 'all') {
      query = query.eq('status', status);
    }

    final rows = await query.order('created_at', ascending: false);

    return (rows as List<dynamic>)
        .map((raw) => MaintenanceRequestRecord.fromMap(raw))
        .toList();
  }

  Future<void> cancelMyRequest({required int requestId}) async {
    final profileIdentity = await _identity.requireCurrentProfile(
      missingMessage: 'No resident profile is linked to this signed-in user.',
    );

    final now = DateTime.now().toUtc().toIso8601String();
    final updated = await _supabase
        .from('maintenance_requests')
        .update({'status': 'cancelled', 'updated_at': now, 'resolved_at': null})
        .eq('id', requestId)
        .eq('resident_id', profileIdentity.id)
        .inFilter('status', ['pending', 'in_progress'])
        .select('id')
        .maybeSingle();

    if (updated == null) {
      throw StateError('This request can no longer be cancelled.');
    }
  }

  Future<_MaintenanceResidentContext> _requireResidentContext() async {
    final profileIdentity = await _identity.requireCurrentProfile(
      missingMessage: 'No resident profile is linked to this signed-in user.',
    );

    final resident = await _supabase
        .from('residents')
        .select(
          'id, unit_id, units(name, condo_id), '
          'profiles!residents_id_fkey(first_name, last_name)',
        )
        .eq('id', profileIdentity.id)
        .single();

    final unit = resident['units'] as Map<String, dynamic>? ?? {};
    final profile = resident['profiles'] as Map<String, dynamic>? ?? {};
    final condoIdValue = unit['condo_id'];
    final unitIdValue = resident['unit_id'];

    return _MaintenanceResidentContext(
      residentId: resident['id'].toString(),
      unitId: unitIdValue is int
          ? unitIdValue
          : int.parse(unitIdValue.toString()),
      condoId: condoIdValue is int
          ? condoIdValue
          : int.parse(condoIdValue.toString()),
      firstName: (profile['first_name'] as String? ?? '').trim(),
      lastName: (profile['last_name'] as String? ?? '').trim(),
      unitName: (unit['name'] as String? ?? '').trim(),
    );
  }
}

class MaintenanceRequestRecord {
  const MaintenanceRequestRecord({
    required this.id,
    required this.createdAt,
    required this.priority,
    required this.problemType,
    required this.description,
    required this.status,
    required this.managerNotes,
    required this.resolvedAt,
  });

  final int id;
  final DateTime? createdAt;
  final String priority;
  final String problemType;
  final String description;
  final String status;
  final String managerNotes;
  final DateTime? resolvedAt;

  factory MaintenanceRequestRecord.fromMap(dynamic mapLike) {
    final map = mapLike as Map<String, dynamic>;
    return MaintenanceRequestRecord(
      id: _parseInt(map['id']),
      createdAt: _parseDateTime(map['created_at']),
      priority: (map['priority'] ?? '').toString(),
      problemType: (map['problem_type'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      managerNotes: (map['manager_notes'] ?? '').toString(),
      resolvedAt: _parseDateTime(map['resolved_at']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class MaintenanceResidentDetails {
  const MaintenanceResidentDetails({
    required this.firstName,
    required this.lastName,
    required this.roomNumber,
  });

  final String firstName;
  final String lastName;
  final String roomNumber;
}

class MaintenanceRequestInput {
  const MaintenanceRequestInput({
    required this.firstName,
    required this.lastName,
    required this.roomNumber,
    required this.priority,
    required this.problemType,
    required this.description,
  });

  final String firstName;
  final String lastName;
  final String roomNumber;
  final String priority;
  final String problemType;
  final String description;
}

class _MaintenanceResidentContext {
  const _MaintenanceResidentContext({
    required this.residentId,
    required this.unitId,
    required this.condoId,
    required this.firstName,
    required this.lastName,
    required this.unitName,
  });

  final String residentId;
  final int unitId;
  final int condoId;
  final String firstName;
  final String lastName;
  final String unitName;
}

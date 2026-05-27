import 'package:mycondo/data/repositories/auth/profile_identity_service.dart';
import 'package:mycondo/services/push/push_event_dispatcher_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManagerMaintenanceRequestsService {
  ManagerMaintenanceRequestsService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;
  final ProfileIdentityService _identity = ProfileIdentityService();
  final PushEventDispatcherService _pushDispatcher =
      PushEventDispatcherService();

  Future<List<ManagerMaintenanceRequest>> fetchRequests({
    String? status,
  }) async {
    final condoId = await _requireManagerCondoId();

    var query = _supabase
        .from('maintenance_requests')
        .select(
          'id, created_at, updated_at, resident_id, unit_id, condo_id, '
          'reporter_first_name, reporter_last_name, room_number, priority, '
          'problem_type, description, status, manager_notes, resolved_at',
        )
        .eq('condo_id', condoId);

    if (status != null && status != 'all') {
      query = query.eq('status', status);
    }

    final rows = await query.order('created_at', ascending: false);

    return (rows as List<dynamic>)
        .map((raw) => ManagerMaintenanceRequest.fromMap(raw))
        .toList();
  }

  Future<void> updateRequestStatus({
    required int requestId,
    required String status,
    String? managerNotes,
  }) async {
    final profile = await _identity.requireCurrentProfile(
      missingMessage: 'No manager profile is linked to this signed-in user.',
    );

    final normalizedStatus = status.toLowerCase().trim();
    final now = DateTime.now().toUtc().toIso8601String();

    final updated = await _supabase
        .from('maintenance_requests')
        .update({
          'status': normalizedStatus,
          'manager_notes': (managerNotes ?? '').trim(),
          'updated_at': now,
          'updated_by': profile.id,
          'resolved_at': normalizedStatus == 'resolved' ? now : null,
        })
        .eq('id', requestId)
        .select('id, resident_id')
        .maybeSingle();

    final residentId = updated?['resident_id']?.toString().trim();
    if (residentId != null && residentId.isNotEmpty) {
      await _pushDispatcher.dispatchMaintenanceUpdated(
        requestId: requestId,
        residentId: residentId,
        status: normalizedStatus,
      );
    }
  }

  Future<int> _requireManagerCondoId() async {
    final profile = await _identity.requireCurrentProfile(
      missingMessage: 'No manager profile is linked to this signed-in user.',
    );

    final row = await _supabase
        .from('managers')
        .select('condo_id')
        .eq('id', profile.id)
        .maybeSingle();

    if (row == null) {
      throw StateError('Only managers can access maintenance requests.');
    }

    final condoId = row['condo_id'];
    if (condoId is int) return condoId;
    return int.parse(condoId.toString());
  }
}

class ManagerMaintenanceRequest {
  const ManagerMaintenanceRequest({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.residentId,
    required this.unitId,
    required this.condoId,
    required this.reporterFirstName,
    required this.reporterLastName,
    required this.roomNumber,
    required this.priority,
    required this.problemType,
    required this.description,
    required this.status,
    required this.managerNotes,
    required this.resolvedAt,
  });

  final int id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String residentId;
  final int unitId;
  final int condoId;
  final String reporterFirstName;
  final String reporterLastName;
  final String roomNumber;
  final String priority;
  final String problemType;
  final String description;
  final String status;
  final String managerNotes;
  final DateTime? resolvedAt;

  String get reporterName {
    final first = reporterFirstName.trim();
    final last = reporterLastName.trim();
    final full = '$first $last'.trim();
    return full.isEmpty ? 'Resident' : full;
  }

  factory ManagerMaintenanceRequest.fromMap(dynamic mapLike) {
    final map = mapLike as Map<String, dynamic>;
    return ManagerMaintenanceRequest(
      id: _parseInt(map['id']),
      createdAt: _parseDateTime(map['created_at']),
      updatedAt: _parseDateTime(map['updated_at']),
      residentId: (map['resident_id'] ?? '').toString(),
      unitId: _parseInt(map['unit_id']),
      condoId: _parseInt(map['condo_id']),
      reporterFirstName: (map['reporter_first_name'] ?? '').toString(),
      reporterLastName: (map['reporter_last_name'] ?? '').toString(),
      roomNumber: (map['room_number'] ?? '').toString(),
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
    return DateTime.tryParse(value.toString())?.toLocal();
  }
}

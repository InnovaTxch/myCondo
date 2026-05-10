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
      'priority': input.priority,
      'problem_type': input.problemType,
      'description': input.description.trim(),
      'status': 'pending',
    });
  }

  Future<_MaintenanceResidentContext> _requireResidentContext() async {
    final profileIdentity = await _identity.requireCurrentProfile(
      missingMessage: 'No resident profile is linked to this signed-in user.',
    );

    final resident = await _supabase
        .from('residents')
        .select(
          'id, unit_id, units(name, condo_id), '
          'profiles!residents_profile_id_fkey(first_name, last_name)',
        )
        .eq('profile_id', profileIdentity.id)
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

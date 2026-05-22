import 'package:mycondo/data/repositories/auth/profile_identity_service.dart';
import 'package:mycondo/data/models/manager/dashboard_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManagerDashboardService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ProfileIdentityService _identity = ProfileIdentityService();

  Future<String?> getFirstName() async {
    final profile = await _identity.getCurrentProfile();
    if (profile == null) return null;

    final data = await _supabase
        .from('profiles')
        .select('first_name')
        .eq('id', profile.id)
        .maybeSingle();

    if (data == null) return null;
    return data['first_name'] as String?;
  }

  Future<DashboardSummary> getDashboardSummary() async {
    final manager = await _requireManagerContext();

    final unitsData = await _supabase
        .from('units')
        .select('id, capacity')
        .eq('condo_id', manager.condoId);

    final units = (unitsData as List).cast<Map<String, dynamic>>();
    final unitIds =
        units.map((row) => (row['id'] as num).toInt()).toList(growable: false);

    var totalCapacity = 0;
    for (final unit in units) {
      final cap = unit['capacity'];
      if (cap is int) {
        totalCapacity += cap;
      } else if (cap is num) {
        totalCapacity += cap.toInt();
      }
    }

    final List<dynamic> residentsData = unitIds.isEmpty
        ? const []
        : await _supabase
            .from('residents')
            .select('id, unit_id')
            .inFilter('unit_id', unitIds)
            .eq('status', 'active');

    final activeUnitIds = residentsData
        .map((row) => (row as Map<String, dynamic>)['unit_id'])
        .where((unitId) => unitId != null)
        .map((unitId) => (unitId as num).toInt())
        .toSet();

    final residentIds = residentsData
        .map((row) => row['id'].toString())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);

    final List<dynamic> paymentsData = residentIds.isEmpty
        ? const []
        : await _supabase
            .from('payments')
            .select('id')
            .inFilter('paid_by', residentIds)
            .eq('status', 'pending');

    final activeUnits = activeUnitIds.length;
    final totalResidents = residentIds.length;
    final totalUnits = unitIds.length;
    final paymentsToReview = paymentsData.length;

    final occupancyPercent = totalCapacity > 0
        ? (totalResidents / totalCapacity).clamp(0, 1).toDouble()
        : null;

    return DashboardSummary()
      ..activeUnits = activeUnits
      ..totalResidents = totalResidents
      ..totalUnits = totalUnits
      ..paymentsToReview = paymentsToReview
      ..occupancyPercent = occupancyPercent
      ..progressLabel = 'Capacity used';
  }

  Future<_ManagerContext> _requireManagerContext() async {
    final profile = await _identity.requireCurrentProfile(
      missingMessage: 'No manager profile is linked to this signed-in user.',
    );

    final manager = await _supabase
        .from('managers')
        .select('id, condo_id')
        .eq('id', profile.id)
        .maybeSingle();

    if (manager == null) {
      throw StateError(
        'Manager account setup is incomplete (missing managers row). Please sign out and complete onboarding again.',
      );
    }

    final condoIdValue = manager['condo_id'];
    final condoId = condoIdValue is int
        ? condoIdValue
        : int.parse(condoIdValue.toString());

    return _ManagerContext(
      managerId: (manager['id'] as String?) ?? profile.id,
      condoId: condoId,
    );
  }
}

class _ManagerContext {
  const _ManagerContext({
    required this.managerId,
    required this.condoId,
  });

  final String managerId;
  final int condoId;
}

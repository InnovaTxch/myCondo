import 'package:mycondo/data/repositories/auth/profile_identity_service.dart';
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
        .single();

    return data['first_name'] as String?;
  }
}

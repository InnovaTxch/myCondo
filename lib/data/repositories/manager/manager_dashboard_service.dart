import 'package:supabase_flutter/supabase_flutter.dart';

class ManagerDashboardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> getFirstName() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _supabase
        .from('profiles')
        .select('first_name')
        .eq('id', userId)
        .single();

    return data['first_name'] as String?;
  }
}
import 'package:supabase_flutter/supabase_flutter.dart';

class ResidentProfileService {
  final supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> getProfile() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception("No user logged in");
    }

    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    final resident = await supabase
        .from('residents')
        .select('code, status, units(name)')
        .eq('profile_id', data['id'])
        .maybeSingle();

    final unit = resident?['units'] as Map<String, dynamic>?;

    return {
      ...data,
      'resident_code': resident?['code'],
      'resident_status': resident?['status'],
      'unit_name': unit?['name'],
    };
  }

  Future<void> updateProfileDetails({
    required String firstName,
    required String lastName,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception("No user logged in");
    }

    await supabase
        .from('profiles')
        .update({'first_name': firstName.trim(), 'last_name': lastName.trim()})
        .eq('id', user.id);
  }
}

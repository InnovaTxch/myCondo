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

    return data;
  }
}
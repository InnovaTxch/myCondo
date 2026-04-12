import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> getRole() async {
  try {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _supabase
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle(); // Use maybeSingle to avoid errors if the profile is missing

    return data?['role'] as String?;
  } catch (e) {
    print("Error fetching role: $e");
    return null;
  }
}

  Future<AuthResponse> signUpWithEmailPassword(String email, String password) async{
    try {
      return await _supabase.auth.signUp(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      throw "An unexpected error occurred";
    }
  }

  //log in with email and password
  Future<AuthResponse> signInWithEmailPassword(String email, String password) async{
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  //sign out
  Future<void> signOut() async{
    await _supabase.auth.signOut();
  }

  String? getCurrentUserEmail(){
    final session = _supabase.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }
}
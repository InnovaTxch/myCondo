import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

class OnboardingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResponse> setupManagerAccount(String condoName) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      
      return await _supabase.from('condos').insert({
        'name': condoName,
        'manager_id': userId,
        'code': await _generateCondoCode()
      });
    } catch (e) {
      throw "An unexpected error occurred";
    }
  }

  Future<String> _generateCondoCode() async {
    bool isUnique = false;
    String code = "";

    while (!isUnique) {
      code = _generateRandomString(8);

      final response = await _supabase
          .from('condos')
          .select('code')
          .eq('code', code)
          .maybeSingle();

      if (response == null) {
        isUnique = true;
      }
    }

    return code;
  }

  String _generateRandomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890';
    Random rnd = Random();
    
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }
}
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

class OnboardingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> setupManagerAccount(String condoName) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw "No user logged in";

      await _supabase.from('profiles').upsert({
        'id': userId,
        'role': 'manager'
      });

      final code = await _generateCondoCode();

      await _supabase.from('condos').insert({
        'name': condoName,
        'manager_id': userId,
        'code': code,
      });

    } catch (e) {
      print("Error in setupManagerAccount: $e");
      throw e.toString(); 
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
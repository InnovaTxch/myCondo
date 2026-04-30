import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> setupManagerAccount(ManagerCondoSetupInput input) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw "No user logged in";

      await _supabase.from('profiles').upsert({
        'id': userId,
        'role': 'manager',
      });

      final code = await _generateCondoCode();

      final condo = await _supabase
          .from('condos')
          .insert({
        'name': input.name.trim(),
        'location': input.location.trim(),
        'description': input.description.trim(),
        'image_url': input.imageUrl.trim(),
        'gallery_urls': input.galleryUrls
            .map((url) => url.trim())
            .where((url) => url.isNotEmpty)
            .toList(),
        'code': code,
      })
          .select('id')
          .single();

      final condoIdValue = condo['id'];
      final condoId = condoIdValue is int
          ? condoIdValue
          : int.parse(condoIdValue.toString());

      await _supabase.from('managers').upsert({
        'id': userId,
        'condo_id': condoId,
      });
    } catch (e) {
      debugPrint("Error in setupManagerAccount: $e");
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

class ManagerCondoSetupInput {
  const ManagerCondoSetupInput({
    required this.name,
    required this.location,
    required this.description,
    required this.imageUrl,
    required this.galleryUrls,
  });

  final String name;
  final String location;
  final String description;
  final String imageUrl;
  final List<String> galleryUrls;
}

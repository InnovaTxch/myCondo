import 'package:mycondo/data/models/shared/condo_about.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CondoAboutService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<CondoAbout> fetchForManager() async {
    final condoId = await _getManagerCondoId();
    return _fetchCondo(condoId);
  }

  Future<CondoAbout> fetchForResident() async {
    final condoId = await _getResidentCondoId();
    return _fetchCondo(condoId);
  }

  Future<void> updateForManager(CondoAbout about) async {
    final condoId = await _getManagerCondoId();
    await _supabase
        .from('condos')
        .update(about.toUpdateMap())
        .eq('id', condoId);
  }

  Future<CondoAbout> _fetchCondo(int condoId) async {
    final data = await _supabase
        .from('condos')
        .select('id, name, location, description, image_url, gallery_urls')
        .eq('id', condoId)
        .single();

    return CondoAbout.fromMap(data);
  }

  Future<int> _getManagerCondoId() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No authenticated manager user found.');
    }

    final manager = await _supabase
        .from('managers')
        .select('condo_id')
        .eq('id', userId)
        .single();

    final value = manager['condo_id'];
    return value is int ? value : int.parse(value.toString());
  }

  Future<int> _getResidentCondoId() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No authenticated resident user found.');
    }

    final resident = await _supabase
        .from('residents')
        .select('units(condo_id)')
        .eq('id', userId)
        .single();

    final unit = resident['units'] as Map<String, dynamic>? ?? {};
    final value = unit['condo_id'];
    return value is int ? value : int.parse(value.toString());
  }
}

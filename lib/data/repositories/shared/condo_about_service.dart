import 'package:mycondo/data/models/shared/condo_about.dart';
import 'package:mycondo/data/repositories/auth/profile_identity_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CondoAboutService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ProfileIdentityService _identity = ProfileIdentityService();

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
    final profile = await _identity.requireCurrentProfile(
      missingMessage: 'No manager profile is linked to this signed-in user.',
    );

    final manager = await _supabase
        .from('managers')
        .select('condo_id')
        .eq('id', profile.id)
        .single();

    final value = manager['condo_id'];
    return value is int ? value : int.parse(value.toString());
  }

  Future<int> _getResidentCondoId() async {
    final profile = await _identity.requireCurrentProfile(
      missingMessage: 'No resident profile is linked to this signed-in user.',
    );

    final resident = await _supabase
        .from('residents')
        .select('units(condo_id)')
        .eq('id', profile.id)
        .single();

    final unit = resident['units'] as Map<String, dynamic>? ?? {};
    final value = unit['condo_id'];
    return value is int ? value : int.parse(value.toString());
  }
}

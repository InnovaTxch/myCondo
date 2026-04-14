import 'package:flutter/foundation.dart';
import 'package:mycondo/data/models/manager/resident_profile.dart';

class ResidentRepository {
  ResidentRepository._();

  static final ResidentRepository instance = ResidentRepository._();

  final ValueNotifier<List<ResidentProfile>> residentsNotifier =
      ValueNotifier<List<ResidentProfile>>(<ResidentProfile>[]);

  Future<List<ResidentProfile>> getResidents({String query = ''}) async {
    final residents = List<ResidentProfile>.from(residentsNotifier.value)
      ..sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return residents;

    return residents
        .where((resident) => resident.matchesQuery(trimmed))
        .toList();
  }

  Future<ResidentProfile?> getResidentById(String residentId) async {
    try {
      return residentsNotifier.value.firstWhere((r) => r.id == residentId);
    } catch (_) {
      return null;
    }
  }

  Future<void> addResident(ResidentUpsertInput input) async {
    final next = List<ResidentProfile>.from(residentsNotifier.value)
      ..add(
        ResidentProfile(
          id: _generateId(),
          name: input.name.trim(),
          unit: input.unit.trim(),
          email: _clean(input.email),
          phone: _clean(input.phone),
          notes: _clean(input.notes),
          avatarUrl: _clean(input.avatarUrl),
        ),
      );
    residentsNotifier.value = next;
  }

  Future<void> updateResident(String residentId, ResidentUpsertInput input) async {
    final current = List<ResidentProfile>.from(residentsNotifier.value);
    final index = current.indexWhere((resident) => resident.id == residentId);
    if (index < 0) return;

    current[index] = current[index].copyWith(
      name: input.name.trim(),
      unit: input.unit.trim(),
      email: _clean(input.email),
      phone: _clean(input.phone),
      notes: _clean(input.notes),
      avatarUrl: _clean(input.avatarUrl),
    );
    residentsNotifier.value = current;
  }

  Future<void> deleteResident(String residentId) async {
    residentsNotifier.value = residentsNotifier.value
        .where((resident) => resident.id != residentId)
        .toList();
  }

  String _generateId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  String? _clean(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}

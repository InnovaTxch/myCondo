class ResidentProfile {
  const ResidentProfile({
    required this.id,
    required this.name,
    required this.unit,
    this.unitId,
    this.email,
    this.phone,
    this.notes,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String unit;
  final int? unitId;
  final String? email;
  final String? phone;
  final String? notes;
  final String? avatarUrl;

  factory ResidentProfile.fromMap(Map<String, dynamic> map) {
    final firstName = map['first_name']?.toString().trim() ?? '';
    final lastName = map['last_name']?.toString().trim() ?? '';
    final combinedName = '$firstName $lastName'.trim();

    return ResidentProfile(
      id: (map['id'] ?? '').toString(),
      name: combinedName.isNotEmpty
          ? combinedName
          : ((map['name'] ?? map['full_name']) ?? '').toString(),
      unit: ((map['unit'] ?? map['unit_label']) ?? '').toString(),
      unitId: map['unit_id'] as int?,
      email: map['email']?.toString(),
      phone: map['phone']?.toString(),
      notes: map['notes']?.toString(),
      avatarUrl: map['avatar_url']?.toString(),
    );
  }

  bool matchesQuery(String query) {
    final q = query.toLowerCase();
    return name.toLowerCase().contains(q) ||
        unit.toLowerCase().contains(q) ||
        (email ?? '').toLowerCase().contains(q) ||
        (phone ?? '').toLowerCase().contains(q);
  }

  ResidentProfile copyWith({
    String? id,
    String? name,
    String? unit,
    int? unitId,
    String? email,
    String? phone,
    String? notes,
    String? avatarUrl,
  }) {
    return ResidentProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      unitId: unitId ?? this.unitId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

class ResidentUpsertInput {
  const ResidentUpsertInput({
    required this.name,
    required this.unitId,
    this.email,
    this.phone,
    this.notes,
    this.avatarUrl,
  });

  final String name;
  final int unitId;
  final String? email;
  final String? phone;
  final String? notes;
  final String? avatarUrl;

  Map<String, dynamic> toMap({String? managerId}) {
    final nameParts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    final firstName = nameParts.isEmpty ? '' : nameParts.first;
    final lastName = nameParts.length <= 1 ? '' : nameParts.sublist(1).join(' ');

    final data = <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'unit_id': unitId,
      'email': _clean(email),
      'phone': _clean(phone),
      'notes': _clean(notes),
      'avatar_url': _clean(avatarUrl),
    };

    if (managerId != null && managerId.isNotEmpty) {
      data['manager_id'] = managerId;
    }

    return data;
  }

  String? _clean(String? value) {
    final text = value?.trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}

class UnitOption {
  const UnitOption({
    required this.id,
    required this.name,
    this.capacity,
  });

  final int id;
  final String name;
  final int? capacity;
}

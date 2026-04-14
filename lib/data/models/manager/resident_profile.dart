class ResidentProfile {
  const ResidentProfile({
    required this.id,
    required this.name,
    required this.unit,
    this.email,
    this.phone,
    this.notes,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String unit;
  final String? email;
  final String? phone;
  final String? notes;
  final String? avatarUrl;

  factory ResidentProfile.fromMap(Map<String, dynamic> map) {
    return ResidentProfile(
      id: (map['id'] ?? '').toString(),
      name: ((map['name'] ?? map['full_name']) ?? '').toString(),
      unit: ((map['unit'] ?? map['unit_label']) ?? '').toString(),
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
    String? email,
    String? phone,
    String? notes,
    String? avatarUrl,
  }) {
    return ResidentProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
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
    required this.unit,
    this.email,
    this.phone,
    this.notes,
    this.avatarUrl,
  });

  final String name;
  final String unit;
  final String? email;
  final String? phone;
  final String? notes;
  final String? avatarUrl;

  Map<String, dynamic> toMap({String? managerId}) {
    final data = <String, dynamic>{
      'name': name.trim(),
      'unit': unit.trim(),
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

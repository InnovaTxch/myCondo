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
    this.status,
    this.condoCode,
    this.residentCode,
  });

  final String id;
  final String name;
  final String unit;
  final int? unitId;
  final String? email;
  final String? phone;
  final String? notes;
  final String? avatarUrl;
  final String? status;
  final String? condoCode;
  final String? residentCode;

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
      status: map['status']?.toString(),
      condoCode: map['condo_code']?.toString(),
      residentCode: map['resident_code']?.toString(),
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
    String? status,
    String? condoCode,
    String? residentCode,
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
      status: status ?? this.status,
      condoCode: condoCode ?? this.condoCode,
      residentCode: residentCode ?? this.residentCode,
    );
  }
}

class ResidentUpsertInput {
  const ResidentUpsertInput({
    required this.firstName,
    required this.lastName,
    required this.unitId,
    this.email,
    this.phone,
    this.notes,
    this.avatarUrl,
  });

  final String firstName;
  final String lastName;
  final int unitId;
  final String? email;
  final String? phone;
  final String? notes;
  final String? avatarUrl;

  String get name => '$firstName $lastName'.trim();

  Map<String, dynamic> toMap({String? managerId}) {
    final data = <String, dynamic>{
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
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
    this.occupied = 0,
  });

  final int id;
  final String name;
  final int? capacity;
  final int occupied;

  bool get isFull => capacity != null && occupied >= capacity!;

  String get capacityLabel {
    if (capacity == null) return '$occupied tenants';
    return '$occupied/$capacity tenants';
  }
}

class UnitResidentGroup {
  const UnitResidentGroup({
    required this.unit,
    required this.residents,
  });

  final UnitOption unit;
  final List<ResidentProfile> residents;

  bool matchesQuery(String query) {
    final q = query.toLowerCase();
    return unit.name.toLowerCase().contains(q) ||
        residents.any((resident) => resident.matchesQuery(q));
  }
}

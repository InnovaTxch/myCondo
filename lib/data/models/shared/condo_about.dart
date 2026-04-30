class CondoAbout {
  const CondoAbout({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    required this.imageUrl,
    required this.galleryUrls,
  });

  final int id;
  final String name;
  final String location;
  final String description;
  final String imageUrl;
  final List<String> galleryUrls;

  factory CondoAbout.fromMap(Map<String, dynamic> map) {
    final rawGallery = map['gallery_urls'];
    final galleryUrls = rawGallery is List
        ? rawGallery
            .map((item) => item?.toString().trim() ?? '')
            .where((item) => item.isNotEmpty)
            .toList()
        : <String>[];

    return CondoAbout(
      id: (map['id'] as num).toInt(),
      name: (map['name'] ?? '').toString(),
      location: (map['location'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      imageUrl: (map['image_url'] ?? '').toString(),
      galleryUrls: galleryUrls,
    );
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name.trim(),
      'location': location.trim(),
      'description': description.trim(),
      'image_url': imageUrl.trim(),
      'gallery_urls': galleryUrls
          .map((url) => url.trim())
          .where((url) => url.isNotEmpty)
          .toList(),
    };
  }

  CondoAbout copyWith({
    String? name,
    String? location,
    String? description,
    String? imageUrl,
    List<String>? galleryUrls,
  }) {
    return CondoAbout(
      id: id,
      name: name ?? this.name,
      location: location ?? this.location,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      galleryUrls: galleryUrls ?? this.galleryUrls,
    );
  }
}

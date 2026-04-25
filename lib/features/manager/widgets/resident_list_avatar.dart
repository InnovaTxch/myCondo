import 'package:flutter/material.dart';
import 'package:mycondo/data/models/manager/resident_profile.dart';

class ResidentListAvatar extends StatelessWidget {
  const ResidentListAvatar({super.key, required this.resident});

  final ResidentProfile resident;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = resident.avatarUrl?.trim() ?? '';
    if (avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(avatarUrl),
        onBackgroundImageError: (exception, stackTrace) {},
      );
    }

    return CircleAvatar(
      radius: 24,
      child: Text(_initials(resident.name)),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();

    if (parts.isEmpty) return '?';
    return parts.map((part) => part[0].toUpperCase()).join();
  }
}

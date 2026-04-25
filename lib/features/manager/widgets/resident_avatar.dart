import 'package:flutter/material.dart';
import 'package:mycondo/data/models/manager/resident_profile.dart';

class ResidentAvatar extends StatelessWidget {
  const ResidentAvatar({super.key, required this.resident});

  final ResidentProfile? resident;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = resident?.avatarUrl?.trim() ?? '';
    if (avatarUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          avatarUrl,
          width: 132,
          height: 132,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fallback(),
        ),
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    final initials = _initials(resident?.name ?? '');

    return Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEF5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ),
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

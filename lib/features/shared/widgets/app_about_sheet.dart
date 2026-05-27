import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:mycondo/theme/app_theme.dart';

Future<void> showAppAboutSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const AppAboutSheet(),
  );
}

class AppAboutSheet extends StatelessWidget {
  const AppAboutSheet({super.key});

  static const String appName = 'myCondo';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
            bottom: Radius.circular(20),
          ),
        ),
        child: FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            final packageInfo = snapshot.data;
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4DCE4),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF4FB),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.apartment_rounded,
                          color: AppColors.primaryBlue,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appName,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.darkText,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Condo management for residents and managers.',
                              style: TextStyle(
                                color: Color(0xFF66737C),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _MetadataCard(packageInfo: packageInfo),
                  if (snapshot.hasError) ...[
                    const SizedBox(height: 10),
                    const _SupportNote(
                      icon: Icons.info_outline_rounded,
                      title: 'Version details unavailable',
                      body:
                          'The app could not read platform metadata on this device.',
                    ),
                  ],
                  const SizedBox(height: 12),
                  const _SupportNote(
                    icon: Icons.groups_2_outlined,
                    title: 'Project',
                    body:
                        'Built for condo operations, resident billing, announcements, maintenance tracking, and manager-resident messaging.',
                  ),
                  const SizedBox(height: 10),
                  const _SupportNote(
                    icon: Icons.support_agent_outlined,
                    title: 'Support Notes',
                    body:
                        'For account, payment, unit, or maintenance concerns, contact your condo administration and include your role, unit, and a short issue description.',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.packageInfo});

  final PackageInfo? packageInfo;

  @override
  Widget build(BuildContext context) {
    final version = _display(packageInfo?.version);
    final buildNumber = _display(packageInfo?.buildNumber);
    final packageName = _display(packageInfo?.packageName);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FCFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EEF7)),
      ),
      child: Column(
        children: [
          const _MetadataRow(label: 'App Name', value: AppAboutSheet.appName),
          _MetadataRow(label: 'Version', value: version),
          _MetadataRow(label: 'Build Number', value: buildNumber),
          _MetadataRow(label: 'Package', value: packageName),
          const _MetadataRow(label: 'Team', value: 'InnovaTxch'),
        ],
      ),
    );
  }

  String _display(String? value) {
    final text = (value ?? '').trim();
    return text.isEmpty ? 'Not available' : text;
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF66737C),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.darkText,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportNote extends StatelessWidget {
  const _SupportNote({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EEF7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4FB),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xFF66737C),
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

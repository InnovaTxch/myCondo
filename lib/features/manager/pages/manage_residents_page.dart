import 'package:flutter/material.dart';
import 'package:mycondo/data/models/manager/resident_profile.dart';
import 'package:mycondo/data/repositories/manager/resident_repository.dart';
import 'package:mycondo/features/manager/pages/resident_details_page.dart';
import 'package:mycondo/features/manager/pages/resident_form_page.dart';

class ManageResidentsPage extends StatefulWidget {
  const ManageResidentsPage({super.key});

  @override
  State<ManageResidentsPage> createState() => _ManageResidentsPageState();
}

class _ManageResidentsPageState extends State<ManageResidentsPage> {
  final ResidentRepository _repository = ResidentRepository.instance;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ResidentProfile> _filterResidents(List<ResidentProfile> residents) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return residents;
    return residents.where((resident) => resident.matchesQuery(query)).toList();
  }

  Future<void> _openAddResident() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ResidentFormPage()),
    );
  }

  Future<void> _openResidentDetails(String residentId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResidentDetailsPage(residentId: residentId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDDF1FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFDDF1FF),
        elevation: 0,
        title: const Text('Manage Residents'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search name, unit, email, or phone',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _openAddResident,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ValueListenableBuilder<List<ResidentProfile>>(
                valueListenable: _repository.residentsNotifier,
                builder: (context, residents, _) {
                  final filtered = _filterResidents(residents);

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text(
                        'No residents yet. Add your first resident profile.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final resident = filtered[index];

                      return Card(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              _ResidentAvatar(resident: resident),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      resident.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Unit ${resident.unit}',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              OutlinedButton(
                                onPressed: () =>
                                    _openResidentDetails(resident.id),
                                child: const Text('View Info'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResidentAvatar extends StatelessWidget {
  const _ResidentAvatar({required this.resident});

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

    final name = resident.name.trim();
    final initials = name.isEmpty
        ? '?'
        : name
            .split(RegExp(r'\\s+'))
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part[0].toUpperCase())
            .join();

    return CircleAvatar(
      radius: 24,
      child: Text(initials),
    );
  }
}

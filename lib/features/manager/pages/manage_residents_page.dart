import 'package:flutter/material.dart';
import 'package:mycondo/data/models/manager/resident_profile.dart';
import 'package:mycondo/data/repositories/manager/resident_repository.dart';
import 'package:mycondo/features/manager/pages/resident_details_page.dart';
import 'package:mycondo/features/manager/pages/resident_form_page.dart';
import 'package:mycondo/features/manager/widgets/resident_list_avatar.dart';

class ManageResidentsPage extends StatefulWidget {
  const ManageResidentsPage({super.key});

  @override
  State<ManageResidentsPage> createState() => _ManageResidentsPageState();
}

class _ManageResidentsPageState extends State<ManageResidentsPage> {
  final ResidentRepository _repository = ResidentRepository.instance;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadResidents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UnitResidentGroup> _filterGroups(List<UnitResidentGroup> groups) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return groups;
    return groups.where((group) => group.matchesQuery(query)).toList();
  }

  Future<void> _loadResidents({bool showLoading = true}) async {
    setState(() {
      _isLoading = showLoading;
      _errorMessage = null;
    });

    try {
      await _repository.refreshResidents();
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openAddResident() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ResidentFormPage()),
    );
    await _loadResidents();
  }

  Future<void> _openResidentDetails(String residentId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResidentDetailsPage(residentId: residentId),
      ),
    );
    await _loadResidents();
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
                      hintText: 'Search name or unit',
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
              child: RefreshIndicator(
                onRefresh: () => _loadResidents(showLoading: false),
                child: _isLoading
                    ? _buildScrollableMessage(
                        child: const CircularProgressIndicator(),
                      )
                    : _errorMessage != null
                        ? _buildScrollableMessage(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Unable to load residents from Supabase.',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: _loadResidents,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : ValueListenableBuilder<List<UnitResidentGroup>>(
                            valueListenable: _repository.unitGroupsNotifier,
                            builder: (context, groups, _) {
                              final filtered = _filterGroups(groups);

                              if (filtered.isEmpty) {
                                return _buildScrollableMessage(
                                  child: const Text(
                                    'No units or residents match your search.',
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }

                              return ListView.separated(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                itemCount: filtered.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) =>
                                    _buildUnitGroup(filtered[index]),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollableMessage({required Widget child}) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 360,
          child: Center(child: child),
        ),
      ],
    );
  }

  Widget _buildUnitGroup(UnitResidentGroup group) {
    final unit = group.unit;
    final isFull = unit.isFull;

    return Card(
      color: Colors.white,
      child: ExpansionTile(
        initiallyExpanded: group.residents.isNotEmpty,
        leading: Icon(
          Icons.apartment_outlined,
          color: isFull ? Colors.redAccent : Colors.black87,
        ),
        title: Text(
          'Unit ${unit.name}',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          unit.capacity == null
              ? '${unit.occupied} tenants'
              : '${unit.occupied} of ${unit.capacity} capacity',
          style: TextStyle(
            color: isFull ? Colors.redAccent : Colors.black54,
          ),
        ),
        children: [
          if (group.residents.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'No tenants in this unit yet.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            )
          else
            ...group.residents.map(_buildResidentTile),
        ],
      ),
    );
  }

  Widget _buildResidentTile(ResidentProfile resident) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          ResidentListAvatar(resident: resident),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              resident.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: () => _openResidentDetails(resident.id),
            child: const Text('View Info'),
          ),
        ],
      ),
    );
  }
}

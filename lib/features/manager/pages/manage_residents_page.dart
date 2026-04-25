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

  List<ResidentProfile> _filterResidents(List<ResidentProfile> residents) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return residents;
    return residents.where((resident) => resident.matchesQuery(query)).toList();
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
                        : ValueListenableBuilder<List<ResidentProfile>>(
                            valueListenable: _repository.residentsNotifier,
                            builder: (context, residents, _) {
                              final filtered = _filterResidents(residents);

                              if (filtered.isEmpty) {
                                return _buildScrollableMessage(
                                  child: const Text(
                                    'No residents yet. Add your first resident profile.',
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
                                itemBuilder: (context, index) {
                                  final resident = filtered[index];

                                  return Card(
                                    color: Colors.white,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          ResidentListAvatar(
                                            resident: resident,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  resident.name,
                                                  style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600,
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
                                                _openResidentDetails(
                                              resident.id,
                                            ),
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
}

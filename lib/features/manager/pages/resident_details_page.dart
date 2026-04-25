import 'package:flutter/material.dart';
import 'package:mycondo/data/models/manager/resident_profile.dart';
import 'package:mycondo/data/repositories/manager/resident_repository.dart';
import 'package:mycondo/features/manager/widgets/resident_avatar.dart';
import 'package:mycondo/features/manager/widgets/resident_bills_section.dart';
import 'package:mycondo/features/manager/widgets/resident_details_header.dart';
import 'package:mycondo/features/manager/widgets/resident_info_field.dart';

class ResidentDetailsPage extends StatefulWidget {
  const ResidentDetailsPage({super.key, required this.residentId});

  final String residentId;

  @override
  State<ResidentDetailsPage> createState() => _ResidentDetailsPageState();
}

class _ResidentDetailsPageState extends State<ResidentDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final ResidentRepository _repository = ResidentRepository.instance;
  final _nameController = TextEditingController();

  ResidentProfile? _resident;
  List<UnitOption> _units = [];
  int? _selectedUnitId;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      await _repository.refreshResidents();
      final units = await _repository.getUnitOptions();
      final resident = await _repository.getResidentById(widget.residentId);
      if (!mounted) return;

      if (resident == null) {
        setState(() {
          _units = units;
          _notFound = true;
          _isLoading = false;
        });
        return;
      }

      _nameController.text = resident.name;
      _selectedUnitId = resident.unitId;

      setState(() {
        _resident = resident;
        _units = units;
        _notFound = false;
        _selectedUnitId =
            _selectedUnitId ?? (units.isNotEmpty ? units.first.id : null);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load resident: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUnitId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a unit.')),
      );
      return;
    }

    try {
      await _repository.updateResident(
        widget.residentId,
        ResidentUpsertInput(
          name: _nameController.text,
          unitId: _selectedUnitId!,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update resident: $e')),
      );
      return;
    }

    if (!mounted) return;
    await _load();
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resident profile updated.')),
    );
  }

  Future<void> _delete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Resident'),
          content: const Text('This will mark this resident as vacated.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    await _repository.deleteResident(widget.residentId);

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF3F1EC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_notFound) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resident Details')),
        body: const Center(
          child: Text('Resident no longer exists in Supabase.'),
        ),
      );
    }

    final resident = _resident;
    final unitName = _unitNameForSelection(resident);
    final status = resident?.status ?? 'active';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1EC),
      body: SafeArea(
        child: Column(
          children: [
            ResidentDetailsHeader(onBack: () => Navigator.pop(context)),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildResidentCard(resident, unitName, status),
                        const SizedBox(height: 22),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ResidentBillsSection(
                            residentId: widget.residentId,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResidentCard(
    ResidentProfile? resident,
    String unitName,
    String status,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ResidentAvatar(resident: resident),
          const SizedBox(height: 16),
          Text(
            resident?.name ?? _nameController.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              fontFamily: 'Urbanist',
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Unit $unitName',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontFamily: 'Urbanist',
            ),
          ),
          const SizedBox(height: 22),
          if (_isEditing)
            _buildEditFields()
          else
            _buildInfoFields(unitName, status),
          const SizedBox(height: 24),
          if (_isEditing) _buildEditActions(resident) else _buildViewActions(),
        ],
      ),
    );
  }

  Widget _buildEditFields() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            filled: true,
            fillColor: Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) {
            if ((value ?? '').trim().isEmpty) return 'Name is required';
            return null;
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          value: _selectedUnitId,
          items: _units
              .map(
                (unit) => DropdownMenuItem<int>(
                  value: unit.id,
                  child: Text(unit.name),
                ),
              )
              .toList(),
          decoration: const InputDecoration(
            labelText: 'Unit',
            filled: true,
            fillColor: Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (value) => setState(() => _selectedUnitId = value),
          validator: (value) {
            if (value == null) return 'Unit is required';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildInfoFields(String unitName, String status) {
    return Column(
      children: [
        ResidentInfoField(
          icon: Icons.home_work_outlined,
          label: 'Unit $unitName',
        ),
        const SizedBox(height: 12),
        ResidentInfoField(
          icon: Icons.verified_user_outlined,
          label: _formatStatus(status),
        ),
        const SizedBox(height: 12),
        ResidentInfoField(
          icon: Icons.badge_outlined,
          label: widget.residentId,
        ),
      ],
    );
  }

  Widget _buildEditActions(ResidentProfile? resident) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save Changes'),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () {
            _nameController.text = resident?.name ?? '';
            _selectedUnitId = resident?.unitId;
            setState(() => _isEditing = false);
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildViewActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => setState(() => _isEditing = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEFEBE8),
                    foregroundColor: const Color(0xFF1A1A1A),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Edit Info'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/add-bills'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEFEBE8),
                    foregroundColor: const Color(0xFF1A1A1A),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Add Dues'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _delete,
            icon: const Icon(Icons.person_remove_outlined),
            label: const Text('Remove Resident'),
          ),
        ),
      ],
    );
  }

  String _formatStatus(String status) {
    final words = status
        .split('_')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}');
    return words.join(' ');
  }

  String _unitNameForSelection(ResidentProfile? resident) {
    for (final unit in _units) {
      if (unit.id == _selectedUnitId) return unit.name;
    }
    return resident?.unit ?? 'Unknown Unit';
  }
}

import 'package:flutter/material.dart';
import 'package:mycondo/data/models/manager/resident_profile.dart';
import 'package:mycondo/data/repositories/manager/resident_repository.dart';

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
        _units = units;
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
          content: const Text('This will permanently remove this profile.'),
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_notFound) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resident Details')),
        body: const Center(
          child: Text('Resident no longer exists in Supabase.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Resident Details')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  enabled: _isEditing,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) return 'Name is required';
                    return null;
                  },
                ),
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
                  decoration: const InputDecoration(labelText: 'Unit'),
                  onChanged: !_isEditing
                      ? null
                      : (value) => setState(() => _selectedUnitId = value),
                  validator: (value) {
                    if (value == null) return 'Unit is required';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                if (_isEditing) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _save,
                      child: const Text('Save Changes'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => setState(() => _isEditing = false),
                    child: const Text('Cancel'),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => setState(() => _isEditing = true),
                      child: const Text('Edit Profile'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _delete,
                      child: const Text('Remove Resident'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

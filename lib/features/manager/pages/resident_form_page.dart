import 'package:flutter/material.dart';
import 'package:mycondo/data/models/manager/resident_profile.dart';
import 'package:mycondo/data/repositories/manager/resident_repository.dart';

class ResidentFormPage extends StatefulWidget {
  const ResidentFormPage({super.key});

  @override
  State<ResidentFormPage> createState() => _ResidentFormPageState();
}

class _ResidentFormPageState extends State<ResidentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final ResidentRepository _repository = ResidentRepository.instance;

  final _nameController = TextEditingController();

  List<UnitOption> _units = [];
  int? _selectedUnitId;
  bool _isLoadingUnits = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUnits() async {
    try {
      final units = await _repository.getUnitOptions();
      if (!mounted) return;
      setState(() {
        _units = units;
        _selectedUnitId = units.isNotEmpty ? units.first.id : null;
        _isLoadingUnits = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingUnits = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load units: $e')),
      );
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

    setState(() => _isSaving = true);

    try {
      await _repository.addResident(
        ResidentUpsertInput(
          name: _nameController.text,
          unitId: _selectedUnitId!,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create resident account: $e')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Resident')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                if (_isLoadingUnits)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(),
                  ),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Name is required';
                    }
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
                  onChanged: _isSaving
                      ? null
                      : (value) => setState(() => _selectedUnitId = value),
                  validator: (value) {
                    if (value == null) {
                      return 'Unit is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving || _isLoadingUnits || _units.isEmpty
                        ? null
                        : _save,
                    child: _isSaving
                        ? const CircularProgressIndicator()
                        : const Text('Create Resident Account'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

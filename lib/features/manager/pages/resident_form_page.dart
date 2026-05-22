import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mycondo/data/models/manager/resident_profile.dart';
import 'package:mycondo/data/repositories/manager/resident_repository.dart';
import 'package:mycondo/utils/app_snackbar.dart';

class ResidentFormPage extends StatefulWidget {
  const ResidentFormPage({super.key, this.initialUnitId});

  final int? initialUnitId;

  @override
  State<ResidentFormPage> createState() => _ResidentFormPageState();
}

class _ResidentFormPageState extends State<ResidentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final ResidentRepository _repository = ResidentRepository.instance;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  List<UnitOption> _units = [];
  int? _selectedUnitId;
  bool _isLoadingUnits = true;
  bool _isSaving = false;
  bool get _hasAnyUnits => _units.isNotEmpty;
  bool get _hasAvailableUnits => _units.any((unit) => !unit.isFull);

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _loadUnits() async {
    try {
      final units = await _repository.getUnitOptions();
      if (!mounted) return;
      final availableUnits = units.where((unit) => !unit.isFull).toList();
      setState(() {
        _units = units;
        final requestedUnitId = widget.initialUnitId;
        final hasRequestedUnit =
            requestedUnitId != null &&
            availableUnits.any((unit) => unit.id == requestedUnitId);
        _selectedUnitId = hasRequestedUnit
            ? requestedUnitId
            : (availableUnits.isNotEmpty ? availableUnits.first.id : null);
        _isLoadingUnits = false;
      });
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _isLoadingUnits = false);
      context.showAppError(
        e,
        stackTrace: st,
        fallbackMessage: 'Could not load units.',
        debugLabel: 'ResidentFormPage.loadUnits',
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUnitId == null) {
      context.showAppSnackBar(
        const SnackBar(content: Text('Please select a unit.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final resident = await _repository.addResident(
        ResidentUpsertInput(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          unitId: _selectedUnitId!,
        ),
      );
      if (!mounted) return;
      await _showProfileDialog(resident);
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      context.showAppError(
        e,
        stackTrace: st,
        fallbackMessage: 'Could not create the resident profile.',
        debugLabel: 'ResidentFormPage.save',
      );
      return;
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _goToManageCondo() async {
    await Navigator.pushNamed(context, '/manage-condo');
    if (!mounted) return;
    await _loadUnits();
  }

  Future<void> _showProfileDialog(ResidentProfile resident) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final condoCode = resident.condoCode ?? '';
        final residentCode = resident.residentCode ?? '';
        final inviteText =
            'Condo code: $condoCode\nResident code: $residentCode';

        return AlertDialog(
          title: const Text('Resident Profile Created'),
          content: SelectableText(
            '${resident.name} can sign up, then enter these onboarding codes:\n\n'
            '$inviteText',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: inviteText));
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: const Text('Copy Codes'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
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
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'First name is required';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Last name is required';
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<int>(
                  initialValue: _selectedUnitId,
                  items: _units
                      .map(
                        (unit) => DropdownMenuItem<int>(
                          value: unit.id,
                          enabled: !unit.isFull,
                          child: Text(
                            '${unit.name} (${unit.capacityLabel})',
                            style: TextStyle(
                              color: unit.isFull ? Colors.black38 : null,
                            ),
                          ),
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
                if (!_isLoadingUnits && !_hasAnyUnits)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      children: [
                        const Text(
                          'No units found yet. Add a unit in Manage Condo before creating a resident profile.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.redAccent),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _goToManageCondo,
                          child: const Text('Go to Manage Condo'),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _isSaving || _isLoadingUnits || _selectedUnitId == null
                        ? null
                        : _save,
                    child: _isSaving
                        ? const CircularProgressIndicator()
                        : const Text('Create Resident Profile'),
                  ),
                ),
                if (!_isLoadingUnits && _hasAnyUnits && !_hasAvailableUnits)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      children: [
                        const Text(
                          'All units are at maximum capacity. Add a unit or increase capacity in Manage Condo.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.redAccent),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _goToManageCondo,
                          child: const Text('Go to Manage Condo'),
                        ),
                      ],
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

import 'package:flutter/material.dart';
import 'package:mycondo/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:mycondo/data/models/manager/resident_profile.dart';
import 'package:mycondo/data/repositories/manager/resident_repository.dart';
import 'package:mycondo/features/manager/widgets/resident_avatar.dart';
import 'package:mycondo/features/manager/pages/manager_bill_breakdown_page.dart';
import 'package:mycondo/features/manager/widgets/resident_bills_section.dart';
import 'package:mycondo/features/manager/widgets/resident_details_header.dart';
import 'package:mycondo/features/manager/widgets/resident_info_field.dart';
import 'package:mycondo/utils/app_snackbar.dart';
import 'package:mycondo/features/shared/widgets/app_states.dart';

class ResidentDetailsPage extends StatefulWidget {
  const ResidentDetailsPage({super.key, required this.residentId});

  final String residentId;

  @override
  State<ResidentDetailsPage> createState() => _ResidentDetailsPageState();
}

class _ResidentDetailsPageState extends State<ResidentDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final ResidentRepository _repository = ResidentRepository.instance;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

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
    _firstNameController.dispose();
    _lastNameController.dispose();
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

      final nameParts = _splitName(resident.name);
      _firstNameController.text = nameParts.$1;
      _lastNameController.text = nameParts.$2;
      _selectedUnitId = resident.unitId;

      setState(() {
        _resident = resident;
        _units = units;
        _notFound = false;
        _selectedUnitId =
            _selectedUnitId ?? (units.isNotEmpty ? units.first.id : null);
        _isLoading = false;
      });
    } catch (e, st) {
      if (!mounted) return;
      context.showAppError(
        e,
        stackTrace: st,
        fallbackMessage: 'Could not load resident details.',
        debugLabel: 'ResidentDetailsPage.load',
      );
      setState(() => _isLoading = false);
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

    try {
      await _repository.updateResident(
        widget.residentId,
        ResidentUpsertInput(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          unitId: _selectedUnitId!,
        ),
      );
    } catch (e, st) {
      if (!mounted) return;
      context.showAppError(
        e,
        stackTrace: st,
        fallbackMessage: 'Could not update this resident.',
        debugLabel: 'ResidentDetailsPage.save',
      );
      return;
    }

    if (!mounted) return;
    await _load();
    if (!mounted) return;
    setState(() => _isEditing = false);
    context.showAppSnackBar(
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

  Future<void> _copyOnboardingCodes() async {
    final resident = _resident;
    if (resident == null) return;

    final condoCode = resident.condoCode;
    final residentCode = resident.residentCode;
    if (condoCode == null ||
        condoCode.isEmpty ||
        residentCode == null ||
        residentCode.isEmpty) {
      context.showAppSnackBar(
        const SnackBar(content: Text('No resident code found.')),
      );
      return;
    }

    await Clipboard.setData(
      ClipboardData(
        text: 'Condo code: $condoCode\nResident code: $residentCode',
      ),
    );

    if (!mounted) return;
    context.showAppSnackBar(
      const SnackBar(content: Text('Onboarding codes copied.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF3F1EC),
        body: AppLoadingState(),
      );
    }

    if (_notFound) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resident Details')),
        body: const AppEmptyState(
          icon: Icons.person_off_outlined,
          title: 'Resident not found',
          message: 'Resident no longer exists in Supabase.',
          card: false,
        ),
      );
    }

    final resident = _resident;
    final unitName = _unitNameForSelection(resident);
    final status = resident?.status ?? 'active';

    return Scaffold(
      backgroundColor: AppColors.lightBlueBackground,
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
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ResidentBillsSection(
                            residentId: widget.residentId,
                            onViewBreakdown: () async {
                              final residentName =
                                  _resident?.name.trim().isNotEmpty == true
                                  ? _resident!.name
                                  : 'Resident';
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ManagerBillBreakdownPage(
                                    residentId: widget.residentId,
                                    residentName: residentName,
                                  ),
                                ),
                              );
                            },
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
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (!_isEditing)
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => setState(() => _isEditing = true),
                icon: const Icon(Icons.edit_outlined),
                color: AppColors.darkText,
                tooltip: 'Edit Info',
              ),
            ),
          ResidentAvatar(resident: resident),
          const SizedBox(height: 16),
          Text(
            resident?.name ??
                '${_firstNameController.text} ${_lastNameController.text}'
                    .trim(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              fontFamily: 'Urbanist',
              color: AppColors.darkText,
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
          controller: _firstNameController,
          decoration: const InputDecoration(
            labelText: 'First Name',
            filled: true,
            fillColor: Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) {
            if ((value ?? '').trim().isEmpty) return 'First name is required';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _lastNameController,
          decoration: const InputDecoration(
            labelText: 'Last Name',
            filled: true,
            fillColor: Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) {
            if ((value ?? '').trim().isEmpty) return 'Last name is required';
            return null;
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: _selectedUnitId,
          items: _units
              .map(
                (unit) => DropdownMenuItem<int>(
                  value: unit.id,
                  enabled: _unitAvailableForEdit(unit),
                  child: Text(
                    '${unit.name} (${unit.capacityLabel})',
                    style: TextStyle(
                      color: _unitAvailableForEdit(unit)
                          ? Colors.black87
                          : Colors.black38,
                    ),
                  ),
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
          label: _onboardingCodeLabel(),
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
            final nameParts = _splitName(resident?.name ?? '');
            _firstNameController.text = nameParts.$1;
            _lastNameController.text = nameParts.$2;
            _selectedUnitId = resident?.unitId;
            setState(() => _isEditing = false);
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildViewActions() {
    final destructiveColor = context.appStatusColors.destructive;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _copyOnboardingCodes,
            icon: const Icon(Icons.copy_outlined),
            label: const Text('Copy Onboarding Codes'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _delete,
            icon: Icon(Icons.person_remove_outlined, color: destructiveColor),
            label: Text(
              'Remove Resident',
              style: TextStyle(color: destructiveColor),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: destructiveColor,
              side: BorderSide(color: destructiveColor),
            ),
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

  String _onboardingCodeLabel() {
    final resident = _resident;
    final residentCode = resident?.residentCode;
    if (residentCode == null || residentCode.isEmpty) {
      return 'Resident code unavailable';
    }
    return 'Resident code $residentCode';
  }

  bool _unitAvailableForEdit(UnitOption unit) {
    if (unit.id == _resident?.unitId) return true;
    return !unit.isFull;
  }

  (String, String) _splitName(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return ('', '');
    if (parts.length == 1) return (parts.first, '');
    return (parts.first, parts.sublist(1).join(' '));
  }
}

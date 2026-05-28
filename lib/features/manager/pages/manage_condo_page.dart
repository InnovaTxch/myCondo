import 'package:flutter/material.dart';
import 'package:mycondo/theme/app_theme.dart';
import 'package:mycondo/data/models/manager/resident_profile.dart';
import 'package:mycondo/data/models/manager/unit_monthly_models.dart';
import 'package:mycondo/data/repositories/manager/condo_unit_repository.dart';
import 'package:mycondo/data/repositories/manager/unit_billing_repository.dart';
import 'package:mycondo/features/manager/pages/unit_profile_page.dart';
import 'package:mycondo/features/manager/widgets/unit_bill_progress_badge.dart';
import 'package:mycondo/utils/app_snackbar.dart';
import 'package:mycondo/utils/user_friendly_error.dart';
import 'package:mycondo/features/shared/widgets/app_states.dart';
import 'package:mycondo/features/shared/widgets/app_page.dart';
import 'package:mycondo/features/shared/widgets/page_header.dart';

class ManageCondoPage extends StatefulWidget {
  const ManageCondoPage({super.key});

  @override
  State<ManageCondoPage> createState() => _ManageCondoPageState();
}

class _ManageCondoPageState extends State<ManageCondoPage> {
  final CondoUnitRepository _repository = CondoUnitRepository.instance;
  final UnitBillingRepository _unitBillingRepository =
      UnitBillingRepository.instance;
  final TextEditingController _searchController = TextEditingController();

  List<UnitOption> _units = [];
  Map<int, UnitBillPaymentSummary> _unitBillSummaries = const {};
  bool _isLoading = true;
  String? _errorMessage;

  List<UnitOption> get _filteredUnits {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _units;

    return _units.where((unit) {
      final capacityText = unit.capacity == null
          ? '${unit.occupied} residents'
          : '${unit.occupied} of ${unit.capacity} capacity';
      final searchable = 'unit ${unit.name} ${unit.name} $capacityText'
          .toLowerCase();
      return searchable.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUnits({bool showLoading = true}) async {
    setState(() {
      _isLoading = showLoading;
      _errorMessage = null;
    });

    try {
      final units = await _repository.getUnits();
      final unitBillSummaries = await _unitBillingRepository
          .getCurrentMonthPaymentSummaries(
            unitIds: units.map((unit) => unit.id).toList(),
          );
      if (!mounted) return;
      setState(() {
        _units = units;
        _unitBillSummaries = unitBillSummaries;
      });
    } catch (e, st) {
      if (!mounted) return;
      debugPrint('[ManageCondoPage.loadUnits] $e');
      debugPrint(st.toString());
      setState(
        () => _errorMessage = UserFriendlyError.messageFor(
          e,
          fallback: 'Unable to load units. Try again.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openUnitSheet([UnitOption? unit]) async {
    final didSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _UnitFormSheet(unit: unit),
    );

    if (didSave == true) {
      await _loadUnits(showLoading: false);
    }
  }

  Future<void> _openUnitProfile(UnitOption unit) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManagerUnitProfilePage(unitId: unit.id),
      ),
    );
    await _loadUnits(showLoading: false);
  }

  @override
  Widget build(BuildContext context) {
    final filteredUnits = _filteredUnits;

    return AppPageScaffold(
      backgroundColor: AppColors.lightBlueBackground,
      appBar: appPageAppBar(context: context, title: 'Manage Condo'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openUnitSheet(),
        icon: const Icon(Icons.add_home_work_outlined),
        label: const Text('Add Unit'),
      ),
      onRefresh: () => _loadUnits(showLoading: false),
      body: _isLoading
          ? const AppScrollableCentered(child: AppLoadingState())
          : _errorMessage != null
          ? AppScrollableCentered(
              child: AppErrorState(
                message: 'Unable to load units. Try again.',
                details: _errorMessage,
                onRetry: () => _loadUnits(showLoading: false),
              ),
            )
          : _units.isEmpty
          ? const AppScrollableCentered(
              child: AppEmptyState(
                icon: Icons.apartment_outlined,
                title: 'No units yet',
                message: 'Add your first condo unit.',
                card: false,
              ),
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: filteredUnits.isEmpty ? 2 : filteredUnits.length + 1,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _UnitSearchField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    onClear: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  );
                }

                if (filteredUnits.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No matching units',
                    message:
                        'Try searching by a different unit name or number.',
                    card: true,
                  );
                }

                final unit = filteredUnits[index - 1];
                return _UnitCard(
                  unit: unit,
                  billSummary:
                      _unitBillSummaries[unit.id] ??
                      UnitBillPaymentSummary.empty(
                        unitId: unit.id,
                        month: DateTime.now(),
                      ),
                  onTap: () => _openUnitProfile(unit),
                );
              },
            ),
    );
  }
}

class _UnitSearchField extends StatelessWidget {
  const _UnitSearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search units',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2ECF5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2ECF5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
      ),
    );
  }
}

class _UnitCard extends StatelessWidget {
  const _UnitCard({
    required this.unit,
    required this.billSummary,
    required this.onTap,
  });

  final UnitOption unit;
  final UnitBillPaymentSummary billSummary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isFull = unit.isFull;

    return Card(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.apartment_outlined,
                color: isFull ? Colors.redAccent : Colors.black87,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unit ${unit.name}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      unit.capacity == null
                          ? '${unit.occupied} residents'
                          : '${unit.occupied} of ${unit.capacity} capacity',
                      style: TextStyle(
                        color: isFull ? Colors.redAccent : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              UnitBillProgressBadge(summary: billSummary),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right_rounded, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnitFormSheet extends StatefulWidget {
  const _UnitFormSheet({this.unit});

  final UnitOption? unit;

  @override
  State<_UnitFormSheet> createState() => _UnitFormSheetState();
}

class _UnitFormSheetState extends State<_UnitFormSheet> {
  final CondoUnitRepository _repository = CondoUnitRepository.instance;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _capacityController = TextEditingController();

  bool _isSaving = false;

  bool get _isEditing => widget.unit != null;

  @override
  void initState() {
    super.initState();
    final unit = widget.unit;
    if (unit != null) {
      _nameController.text = unit.name;
      _capacityController.text = unit.capacity?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final capacity = int.parse(_capacityController.text.trim());
      if (_isEditing) {
        await _repository.updateUnit(
          id: widget.unit!.id,
          name: _nameController.text,
          capacity: capacity,
        );
      } else {
        await _repository.addUnit(
          name: _nameController.text,
          capacity: capacity,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e, st) {
      if (!mounted) return;
      context.showAppError(
        e,
        stackTrace: st,
        fallbackMessage: 'Could not save this unit.',
        debugLabel: 'ManageCondoPage.saveUnit',
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing ? 'Edit Unit' : 'Add Unit',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Unit Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Unit name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Maximum Capacity',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final capacity = int.tryParse((value ?? '').trim());
                  if (capacity == null || capacity <= 0) {
                    return 'Enter a capacity greater than 0';
                  }
                  final occupied = widget.unit?.occupied ?? 0;
                  if (capacity < occupied) {
                    return 'Capacity cannot be below current residents';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isEditing ? 'Save Unit' : 'Add Unit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

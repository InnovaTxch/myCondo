import 'package:flutter/material.dart';
import 'package:mycondo/theme/app_theme.dart';
import 'package:mycondo/data/models/manager/resident_profile.dart';
import 'package:mycondo/data/models/manager/unit_monthly_models.dart';
import 'package:mycondo/data/repositories/manager/condo_unit_repository.dart';
import 'package:mycondo/data/repositories/manager/resident_repository.dart';
import 'package:mycondo/data/repositories/manager/unit_billing_repository.dart';
import 'package:mycondo/features/manager/pages/resident_details_page.dart';
import 'package:mycondo/features/manager/pages/resident_form_page.dart';
import 'package:mycondo/features/manager/widgets/resident_list_avatar.dart';
import 'package:mycondo/features/manager/widgets/unit_bill_progress_badge.dart';
import 'package:mycondo/features/shared/widgets/app_states.dart';
import 'package:mycondo/features/shared/widgets/app_page.dart';
import 'package:mycondo/utils/app_snackbar.dart';
import 'package:mycondo/utils/user_friendly_error.dart';

class ManageResidentsPage extends StatefulWidget {
  const ManageResidentsPage({super.key});

  @override
  State<ManageResidentsPage> createState() => _ManageResidentsPageState();
}

class _ManageResidentsPageState extends State<ManageResidentsPage> {
  final ResidentRepository _repository = ResidentRepository.instance;
  final CondoUnitRepository _unitRepository = CondoUnitRepository.instance;
  final UnitBillingRepository _unitBillingRepository =
      UnitBillingRepository.instance;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _newUnitNameController = TextEditingController();
  final TextEditingController _newUnitCapacityController =
      TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;
  Map<int, UnitBillPaymentSummary> _unitBillSummaries = const {};
  bool _isAddingUnitInline = false;
  bool _isSavingUnitInline = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadResidents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newUnitNameController.dispose();
    _newUnitCapacityController.dispose();
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
      final unitIds = _repository.unitGroupsNotifier.value
          .map((group) => group.unit.id)
          .toList();
      final unitBillSummaries = await _unitBillingRepository
          .getCurrentMonthPaymentSummaries(unitIds: unitIds);
      if (!mounted) return;
      setState(() => _unitBillSummaries = unitBillSummaries);
    } catch (e, st) {
      if (!mounted) return;
      debugPrint('[ManageResidentsPage.loadResidents] $e');
      debugPrint(st.toString());
      setState(
        () => _errorMessage = UserFriendlyError.messageFor(
          e,
          fallback: 'Unable to load residents. Try again.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openAddResident([int? initialUnitId]) async {
    try {
      final units = await _repository.getUnitOptions();
      if (!mounted) return;
      if (units.isEmpty) {
        context.showAppSnackBar(
          SnackBar(
            content: const Text(
              'Add at least one unit first before adding residents.',
            ),
            action: SnackBarAction(
              label: 'Add Unit',
              onPressed: () => setState(() => _isAddingUnitInline = true),
            ),
          ),
        );
        return;
      }
    } catch (e, st) {
      if (!mounted) return;
      context.showAppError(
        e,
        stackTrace: st,
        fallbackMessage: 'Could not load available units.',
        debugLabel: 'ManageResidentsPage.openAddResident',
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResidentFormPage(initialUnitId: initialUnitId),
      ),
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

  Future<void> _saveInlineUnit() async {
    final name = _newUnitNameController.text.trim();
    final capacity = int.tryParse(_newUnitCapacityController.text.trim());
    if (name.isEmpty) {
      context.showAppSnackBar(
        const SnackBar(content: Text('Unit name is required.')),
      );
      return;
    }
    if (capacity == null || capacity <= 0) {
      context.showAppSnackBar(
        const SnackBar(content: Text('Enter a valid capacity greater than 0.')),
      );
      return;
    }

    setState(() => _isSavingUnitInline = true);
    try {
      await _unitRepository.addUnit(name: name, capacity: capacity);
      if (!mounted) return;
      setState(() {
        _newUnitNameController.clear();
        _newUnitCapacityController.clear();
        _isAddingUnitInline = false;
      });
      await _loadResidents(showLoading: false);
      if (!mounted) return;
      context.showAppSnackBar(
        const SnackBar(content: Text('Unit added. You can now add residents.')),
      );
    } catch (e, st) {
      if (!mounted) return;
      context.showAppError(
        e,
        stackTrace: st,
        fallbackMessage: 'Could not save this unit.',
        debugLabel: 'ManageResidentsPage.saveInlineUnit',
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingUnitInline = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      backgroundColor: AppColors.lightBlueBackground,
      appBar: AppBar(
        backgroundColor: AppColors.lightBlueBackground,
        elevation: 0,
        title: const Text('Manage Residents'),
      ),
      onRefresh: () => _loadResidents(showLoading: false),
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
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSavingUnitInline
                    ? null
                    : () => setState(
                        () => _isAddingUnitInline = !_isAddingUnitInline,
                      ),
                icon: const Icon(Icons.add_home_work_outlined),
                label: Text(_isAddingUnitInline ? 'Cancel' : 'Add Unit'),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: _isLoading
                  ? const AppScrollableCentered(child: AppLoadingState())
                  : _errorMessage != null
                  ? AppScrollableCentered(
                      child: AppErrorState(
                        message: 'Unable to load residents. Try again.',
                        details: _errorMessage,
                        onRetry: () => _loadResidents(),
                      ),
                    )
                  : ValueListenableBuilder<List<UnitResidentGroup>>(
                      valueListenable: _repository.unitGroupsNotifier,
                      builder: (context, groups, _) {
                        final filtered = _filterGroups(groups);
                        return Column(
                          children: [
                            _buildInlineUnitComposer(),
                            if (_isAddingUnitInline) const SizedBox(height: 6),
                            if (filtered.isEmpty)
                              const Expanded(
                                child: AppScrollableCentered(
                                  child: AppEmptyState(
                                    icon: Icons.search_rounded,
                                    title: 'No results',
                                    message:
                                        'No units or residents match your search.',
                                    card: false,
                                  ),
                                ),
                              )
                            else
                              Expanded(
                                child: ListView.separated(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  itemCount: filtered.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) =>
                                      _buildUnitGroup(filtered[index]),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitGroup(UnitResidentGroup group) {
    final unit = group.unit;
    final isFull = unit.isFull;
    final billSummary =
        _unitBillSummaries[unit.id] ??
        UnitBillPaymentSummary.empty(unitId: unit.id, month: DateTime.now());

    return Card(
      color: Colors.white,
      child: ExpansionTile(
        initiallyExpanded: group.residents.isNotEmpty,
        leading: Icon(
          Icons.apartment_outlined,
          color: isFull ? Colors.redAccent : Colors.black87,
        ),
        title: Row(
          children: [
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
                  const SizedBox(height: 3),
                  _buildCapacityStatus(unit),
                ],
              ),
            ),
            UnitBillProgressBadge(summary: billSummary, showAmounts: false),
          ],
        ),
        children: [
          if (group.residents.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'No residents in this unit yet.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            )
          else
            ...group.residents.map(_buildResidentTile),
          if (!isFull)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openAddResident(unit.id),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Add Resident'),
                ),
              ),
            ),
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
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
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

  Widget _buildInlineUnitComposer() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      child: !_isAddingUnitInline
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.fromLTRB(2, 2, 2, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _newUnitNameController,
                    enabled: !_isSavingUnitInline,
                    decoration: const InputDecoration(
                      labelText: 'Unit Name',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _newUnitCapacityController,
                    enabled: !_isSavingUnitInline,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Maximum Capacity',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _isSavingUnitInline ? null : _saveInlineUnit,
                      child: _isSavingUnitInline
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Unit'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCapacityStatus(UnitOption unit) {
    final capacity = unit.capacity;
    if (capacity == null || capacity <= 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.groups_2_outlined,
            size: 16,
            color: AppColors.secondaryText,
          ),
          const SizedBox(width: 5),
          Text(
            '${unit.occupied} residents assigned',
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    final occupied = unit.occupied.clamp(0, capacity);
    final isFull = occupied >= capacity;
    final color = isFull ? AppColors.errorRed : AppColors.primaryBlue;

    return Row(
      children: [
        Icon(Icons.groups_2_outlined, size: 16, color: color),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            '$occupied of $capacity residents',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

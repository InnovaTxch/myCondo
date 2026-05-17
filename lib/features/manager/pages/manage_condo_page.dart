import 'package:flutter/material.dart';
import 'package:mycondo/theme/app_theme.dart';
import 'package:mycondo/data/models/manager/resident_profile.dart';
import 'package:mycondo/data/repositories/manager/condo_unit_repository.dart';
import 'package:mycondo/utils/app_snackbar.dart';
import 'package:mycondo/features/shared/widgets/app_states.dart';
import 'package:mycondo/features/shared/widgets/app_page.dart';

class ManageCondoPage extends StatefulWidget {
  const ManageCondoPage({super.key});

  @override
  State<ManageCondoPage> createState() => _ManageCondoPageState();
}

class _ManageCondoPageState extends State<ManageCondoPage> {
  final CondoUnitRepository _repository = CondoUnitRepository.instance;

  List<UnitOption> _units = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits({bool showLoading = true}) async {
    setState(() {
      _isLoading = showLoading;
      _errorMessage = null;
    });

    try {
      final units = await _repository.getUnits();
      if (!mounted) return;
      setState(() => _units = units);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
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

  Future<void> _deleteUnit(UnitOption unit) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Unit ${unit.name}?'),
        content: Text(
          unit.occupied > 0
              ? 'This unit has residents. Move or remove them before deleting it.'
              : 'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed:
                unit.occupied > 0 ? null : () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await _repository.deleteUnit(unit);
      await _loadUnits(showLoading: false);
    } catch (e) {
      if (!mounted) return;
      context.showAppSnackBar(
        SnackBar(content: Text('Failed to delete unit: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      backgroundColor: AppColors.lightBlueBackground,
      appBar: AppBar(
        backgroundColor: AppColors.lightBlueBackground,
        elevation: 0,
        title: const Text('Manage Condo'),
      ),
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
                      itemCount: _units.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final unit = _units[index];
                        return _UnitCard(
                          unit: unit,
                          onEdit: () => _openUnitSheet(unit),
                          onDelete: () => _deleteUnit(unit),
                        );
                      },
                    ),
    );
  }
}

class _UnitCard extends StatelessWidget {
  const _UnitCard({
    required this.unit,
    required this.onEdit,
    required this.onDelete,
  });

  final UnitOption unit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isFull = unit.isFull;

    return Card(
      color: Colors.white,
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
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
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
    } catch (e) {
      if (!mounted) return;
      context.showAppSnackBar(SnackBar(content: Text('Failed to save unit: $e')));
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


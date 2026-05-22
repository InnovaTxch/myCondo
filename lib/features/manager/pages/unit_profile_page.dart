import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mycondo/data/models/manager/resident_profile.dart';
import 'package:mycondo/data/models/manager/unit_monthly_models.dart';
import 'package:mycondo/data/repositories/manager/unit_billing_repository.dart';
import 'package:mycondo/features/shared/widgets/app_states.dart';
import 'package:mycondo/theme/app_theme.dart';
import 'package:mycondo/utils/app_snackbar.dart';
import 'package:mycondo/utils/user_friendly_error.dart';

class ManagerUnitProfilePage extends StatefulWidget {
  const ManagerUnitProfilePage({super.key, required this.unitId});

  final int unitId;

  @override
  State<ManagerUnitProfilePage> createState() => _ManagerUnitProfilePageState();
}

class _ManagerUnitProfilePageState extends State<ManagerUnitProfilePage> {
  final UnitBillingRepository _repository = UnitBillingRepository.instance;
  DateTime _selectedMonth = _toMonth(DateTime.now());

  UnitOption? _unit;
  List<UnitMonthlyChargeTemplate> _templates = const [];
  List<UnitPaymentPayer> _payers = const [];
  final Map<String, UnitMonthlyLedger> _ledgerByMonth = {};

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() => _errorMessage = null);
    }

    try {
      final unit = await _repository.getUnitById(widget.unitId);
      final templates = await _repository.getUnitMonthlyChargeTemplates(
        widget.unitId,
      );
      final payers = await _repository.getUnitPayers(widget.unitId);
      if (!mounted) return;
      setState(() {
        _unit = unit;
        _templates = templates;
        _payers = payers;
      });
      await _loadLedgerForMonth(_selectedMonth);
    } catch (e, st) {
      if (!mounted) return;
      debugPrint('[ManagerUnitProfilePage.loadAll] $e');
      debugPrint(st.toString());
      setState(
        () => _errorMessage = UserFriendlyError.messageFor(
          e,
          fallback: 'Unable to load unit profile.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadLedgerForMonth(DateTime month) async {
    final key = _monthKey(month);
    if (_ledgerByMonth.containsKey(key)) return;
    try {
      final ledger = await _repository.getUnitMonthlyLedgerForManager(
        unitId: widget.unitId,
        month: month,
      );
      if (!mounted) return;
      setState(() => _ledgerByMonth[key] = ledger);
    } catch (_) {
      // Keep UI responsive and show fallback card state.
    }
  }

  Future<void> _selectMonth(DateTime month) async {
    final normalized = _toMonth(month);
    setState(() => _selectedMonth = normalized);
    await _loadLedgerForMonth(normalized);
  }

  Future<void> _moveMonth(int offset) {
    return _selectMonth(
      DateTime(_selectedMonth.year, _selectedMonth.month + offset, 1),
    );
  }

  Future<void> _openEditUnitSheet() async {
    final unit = _unit;
    if (unit == null) return;
    final nameController = TextEditingController(text: unit.name);
    final capacityController = TextEditingController(
      text: (unit.capacity ?? 1).toString(),
    );
    final formKey = GlobalKey<FormState>();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Unit Profile',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Unit Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Unit name is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: capacityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Maximum Capacity',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final parsed = int.tryParse((value ?? '').trim());
                      if (parsed == null || parsed <= 0) {
                        return 'Enter a capacity greater than 0.';
                      }
                      if (parsed < unit.occupied) {
                        return 'Capacity cannot be below current residents.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        Navigator.pop(context, true);
                      },
                      child: const Text('Save Unit'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (saved != true) return;
    final capacity = int.tryParse(capacityController.text.trim());
    if (capacity == null) return;
    await _withSaving(() async {
      await _repository.updateUnit(
        unitId: widget.unitId,
        name: nameController.text.trim(),
        capacity: capacity,
      );
      await _loadAll(showLoading: false);
    });
  }

  Future<void> _deleteUnit() async {
    final unit = _unit;
    if (unit == null) return;

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
            onPressed: unit.occupied > 0
                ? null
                : () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    await _withSaving(() async {
      await _repository.deleteUnit(unit);
      if (!mounted) return;
      Navigator.pop(context, true);
    });
  }

  Future<void> _openAddChargeSheet() async {
    final applyMonth = await _promptApplyMonth();
    if (applyMonth == null) return;
    if (!mounted) return;

    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Monthly Charge',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Charge Name (Rent, Internet, etc.)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Charge name is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Amount (PHP)',
                      border: OutlineInputBorder(),
                      prefixText: 'PHP ',
                    ),
                    validator: (value) {
                      final amount = double.tryParse((value ?? '').trim());
                      if (amount == null || amount <= 0) {
                        return 'Enter an amount greater than zero.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        Navigator.pop(context, true);
                      },
                      child: const Text('Add Charge'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (confirmed != true) return;

    final amount = double.tryParse(amountController.text.trim());
    if (amount == null) return;

    await _withSaving(() async {
      await _repository.addChargeTemplate(
        unitId: widget.unitId,
        name: nameController.text.trim(),
        amount: (amount * 100).round(),
        applyMonth: applyMonth,
      );
      _ledgerByMonth.clear();
      await _loadAll(showLoading: false);
    });
  }

  Future<void> _openEditChargeSheet(UnitMonthlyChargeTemplate template) async {
    final applyMonth = await _promptApplyMonth();
    if (applyMonth == null) return;
    if (!mounted) return;

    final nameController = TextEditingController(text: template.name);
    final amountController = TextEditingController(
      text: (template.amount / 100).toStringAsFixed(2),
    );
    final formKey = GlobalKey<FormState>();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Monthly Charge',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Charge Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Charge name is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Amount (PHP)',
                      border: OutlineInputBorder(),
                      prefixText: 'PHP ',
                    ),
                    validator: (value) {
                      final amount = double.tryParse((value ?? '').trim());
                      if (amount == null || amount <= 0) {
                        return 'Enter an amount greater than zero.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        Navigator.pop(context, true);
                      },
                      child: const Text('Save Charge'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (confirmed != true) return;

    final amount = double.tryParse(amountController.text.trim());
    if (amount == null) return;

    await _withSaving(() async {
      await _repository.updateChargeTemplate(
        template: template,
        name: nameController.text.trim(),
        amount: (amount * 100).round(),
        applyMonth: applyMonth,
      );
      _ledgerByMonth.clear();
      await _loadAll(showLoading: false);
    });
  }

  Future<void> _deleteCharge(UnitMonthlyChargeTemplate template) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Monthly Charge'),
        content: Text('Remove "${template.name}" from this unit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final applyMonth = await _promptApplyMonth();
    if (applyMonth == null) return;

    await _withSaving(() async {
      await _repository.deleteChargeTemplate(
        template: template,
        applyMonth: applyMonth,
      );
      _ledgerByMonth.clear();
      await _loadAll(showLoading: false);
    });
  }

  Future<ApplyChargeChangeMonth?> _promptApplyMonth() async {
    return showDialog<ApplyChargeChangeMonth>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply Change'),
        content: const Text(
          'Apply this monthly bill change to this month or next month?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, ApplyChargeChangeMonth.nextMonth),
            child: const Text('Next Month'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, ApplyChargeChangeMonth.currentMonth),
            child: const Text('This Month'),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddOneTimeBillSheet(DateTime month) async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add One-Time Bill - ${DateFormat('MMMM yyyy').format(month)}',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This bill applies only to this selected month.',
                    style: TextStyle(color: AppColors.secondaryText),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Bill Name (Cleaning service, repairs, etc.)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Bill name is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Amount (PHP)',
                      border: OutlineInputBorder(),
                      prefixText: 'PHP ',
                    ),
                    validator: (value) {
                      final amount = double.tryParse((value ?? '').trim());
                      if (amount == null || amount <= 0) {
                        return 'Enter an amount greater than zero.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        Navigator.pop(context, true);
                      },
                      child: const Text('Issue One-Time Bill'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;
    final amount = double.tryParse(amountController.text.trim());
    if (amount == null) return;

    await _withSaving(() async {
      await _repository.addOneTimeUnitBill(
        unitId: widget.unitId,
        month: month,
        name: nameController.text.trim(),
        amount: (amount * 100).round(),
      );
      _ledgerByMonth.remove(_monthKey(month));
      await _loadLedgerForMonth(month);
    });
  }

  Future<void> _withSaving(Future<void> Function() action) async {
    setState(() => _isSaving = true);
    try {
      await action();
    } catch (e, st) {
      if (!mounted) return;
      context.showAppError(
        e,
        stackTrace: st,
        fallbackMessage: 'Could not complete that action.',
        debugLabel: 'ManagerUnitProfilePage.withSaving',
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _openAddPaymentSheet(DateTime month) async {
    if (_payers.isEmpty) {
      context.showAppSnackBar(
        const SnackBar(
          content: Text(
            'No active residents found in this unit. Add a resident first.',
          ),
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    String selectedPayerId = _payers.first.id;
    String selectedMethod = 'Cash';
    const methods = <String>[
      'Cash',
      'GCash',
      'Bank Transfer',
      'Credit Card',
      'Cheque',
      'Other',
    ];

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Payment - ${DateFormat('MMMM yyyy').format(month)}',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedPayerId,
                        decoration: const InputDecoration(
                          labelText: 'Who paid',
                          border: OutlineInputBorder(),
                        ),
                        items: _payers
                            .map(
                              (payer) => DropdownMenuItem<String>(
                                value: payer.id,
                                child: Text(payer.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setSheetState(() => selectedPayerId = value);
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'How much',
                          border: OutlineInputBorder(),
                          prefixText: 'PHP ',
                        ),
                        validator: (value) {
                          final amount = double.tryParse((value ?? '').trim());
                          if (amount == null || amount <= 0) {
                            return 'Enter an amount greater than zero.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: selectedMethod,
                        decoration: const InputDecoration(
                          labelText: 'Via what',
                          border: OutlineInputBorder(),
                        ),
                        items: methods
                            .map(
                              (method) => DropdownMenuItem<String>(
                                value: method,
                                child: Text(method),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setSheetState(() => selectedMethod = value);
                        },
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (!formKey.currentState!.validate()) return;
                            Navigator.pop(context, true);
                          },
                          child: const Text('Record Payment'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmed != true) return;
    final amount = double.tryParse(amountController.text.trim());
    if (amount == null) return;

    await _withSaving(() async {
      await _repository.addManagerUnitPayment(
        unitId: widget.unitId,
        month: month,
        paidByResidentId: selectedPayerId,
        amount: (amount * 100).round(),
        paymentMethod: selectedMethod,
      );
      _ledgerByMonth.remove(_monthKey(month));
      await _loadLedgerForMonth(month);
      await _loadAll(showLoading: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final unit = _unit;
    return Scaffold(
      backgroundColor: AppColors.lightBlueBackground,
      appBar: AppBar(
        backgroundColor: AppColors.lightBlueBackground,
        title: Text(unit == null ? 'Unit Profile' : 'Unit ${unit.name}'),
      ),
      body: _isLoading
          ? const AppLoadingState()
          : _errorMessage != null
          ? Center(
              child: AppErrorState(
                message: 'Unable to load unit profile.',
                onRetry: () => _loadAll(showLoading: true),
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _loadAll(showLoading: false),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                children: [
                  _buildUnitInfoCard(unit!),
                  const SizedBox(height: 12),
                  _buildMonthlyChargesCard(),
                  const SizedBox(height: 12),
                  _buildMonthlyPaymentsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildUnitInfoCard(UnitOption unit) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Unit Profile',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Name: Unit ${unit.name}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              unit.capacity == null
                  ? 'Capacity: Unlimited'
                  : 'Capacity: ${unit.capacity}',
            ),
            const SizedBox(height: 4),
            Text('Occupied: ${unit.occupied} resident(s)'),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : _openEditUnitSheet,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit Unit'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : _deleteUnit,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete Unit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.errorRed,
                      side: const BorderSide(color: AppColors.errorRed),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyChargesCard() {
    final currency = NumberFormat.currency(symbol: 'PHP ', decimalDigits: 2);
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Monthly Bills',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _openAddChargeSheet,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_templates.isEmpty)
              const Text(
                'No monthly charges yet. Add Rent, Internet, Cable, and other recurring charges.',
                style: TextStyle(color: AppColors.secondaryText),
              )
            else
              ..._templates.map((template) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(template.name),
                  subtitle: Text(currency.format(template.amount / 100)),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        onPressed: _isSaving
                            ? null
                            : () => _openEditChargeSheet(template),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        onPressed: _isSaving
                            ? null
                            : () => _deleteCharge(template),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyPaymentsCard() {
    final ledger = _ledgerByMonth[_monthKey(_selectedMonth)];

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Payments',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: _isSaving ? null : () => _moveMonth(-1),
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: 'Previous month',
                ),
                Text(
                  DateFormat('MMM yyyy').format(_selectedMonth),
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  onPressed: _isSaving ? null : () => _moveMonth(1),
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: 'Next month',
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () => _openAddOneTimeBillSheet(_selectedMonth),
                icon: const Icon(Icons.add_card_outlined, size: 16),
                label: const Text('Add One-Time Bill'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed:
                    _isSaving || ledger == null || !ledger.hasAssignedBill
                    ? null
                    : () => _openAddPaymentSheet(_selectedMonth),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Payment'),
              ),
            ),
            const SizedBox(height: 10),
            if (ledger == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              _MonthlyLedgerPanel(ledger: ledger),
          ],
        ),
      ),
    );
  }

  static DateTime _toMonth(DateTime date) => DateTime(date.year, date.month, 1);

  static String _monthKey(DateTime month) =>
      '${month.year}-${month.month.toString().padLeft(2, '0')}';
}

class _MonthlyLedgerPanel extends StatelessWidget {
  const _MonthlyLedgerPanel({required this.ledger});

  final UnitMonthlyLedger ledger;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'PHP ', decimalDigits: 2);
    final statusColor = _statusColor(ledger.status);
    final monthLabel = DateFormat('MMMM yyyy').format(ledger.month);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FCFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2ECF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  monthLabel,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (ledger.hasAssignedBill)
                Text(
                  _statusLabel(ledger.status),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          if (!ledger.hasAssignedBill) ...[
            const SizedBox(height: 14),
            const Align(
              alignment: Alignment.topLeft,
              child: Text(
                'No unit bill has been assigned for this month.',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            ...ledger.charges.map((charge) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            charge.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            charge.isOneTime ? 'One-time' : 'Monthly',
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      currency.format(charge.amount / 100),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              );
            }),
            const Divider(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total Bill Amount',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  currency.format(ledger.totalAmount / 100),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (ledger.payments.isEmpty)
              const Align(
                alignment: Alignment.topLeft,
                child: Text(
                  'No approved payments yet for this month.',
                  style: TextStyle(color: AppColors.secondaryText),
                ),
              )
            else
              ...ledger.payments.map((payment) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              payment.residentName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('MMM d, yyyy').format(payment.paidAt),
                              style: const TextStyle(
                                color: AppColors.secondaryText,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text('- ${currency.format(payment.amount / 100)}'),
                    ],
                  ),
                );
              }),
            const Divider(height: 14),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Remaining Amount',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  currency.format(ledger.remainingAmount / 100),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: ledger.remainingAmount > 0
                        ? AppColors.errorRed
                        : AppColors.successGreen,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'Paid';
      case 'partial':
        return 'Partial';
      case 'overdue':
        return 'Overdue';
      default:
        return 'Unpaid';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return AppColors.successGreen;
      case 'partial':
        return AppColors.primaryBlue;
      case 'overdue':
        return AppColors.errorRed;
      default:
        return AppColors.warningOrange;
    }
  }
}

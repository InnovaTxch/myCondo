import 'package:mycondo/data/models/manager/resident_profile.dart';
import 'package:mycondo/data/models/manager/unit_monthly_models.dart';
import 'package:mycondo/data/repositories/auth/profile_identity_service.dart';
import 'package:mycondo/data/repositories/manager/condo_unit_repository.dart';
import 'package:mycondo/services/push/push_event_dispatcher_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UnitBillingRepository {
  UnitBillingRepository._();

  static final UnitBillingRepository instance = UnitBillingRepository._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final CondoUnitRepository _unitRepository = CondoUnitRepository.instance;
  final ProfileIdentityService _identity = ProfileIdentityService();
  final PushEventDispatcherService _pushDispatcher =
      PushEventDispatcherService();

  Future<UnitOption> getUnitById(int unitId) async {
    final units = await _unitRepository.getUnits();
    return units.firstWhere((unit) => unit.id == unitId);
  }

  Future<List<UnitPaymentPayer>> getUnitPayers(int unitId) async {
    final residents = await _supabase
        .from('residents')
        .select('id, profiles!residents_id_fkey(first_name, last_name)')
        .eq('unit_id', unitId)
        .eq('status', 'active');

    return (residents as List).map((row) {
      final map = row as Map<String, dynamic>;
      final profile = map['profiles'] as Map<String, dynamic>? ?? {};
      final firstName = (profile['first_name'] ?? '').toString().trim();
      final lastName = (profile['last_name'] ?? '').toString().trim();
      final fullName = [
        firstName,
        lastName,
      ].where((part) => part.isNotEmpty).join(' ');
      return UnitPaymentPayer(
        id: (map['id'] ?? '').toString(),
        name: fullName.isEmpty ? 'Resident' : fullName,
      );
    }).toList();
  }

  Future<void> updateUnit({
    required int unitId,
    required String name,
    required int capacity,
  }) {
    return _unitRepository.updateUnit(
      id: unitId,
      name: name,
      capacity: capacity,
    );
  }

  Future<void> deleteUnit(UnitOption unit) {
    return _unitRepository.deleteUnit(unit);
  }

  Future<List<UnitMonthlyChargeTemplate>> getUnitMonthlyChargeTemplates(
    int unitId,
  ) async {
    final data = await _supabase
        .from('unit_monthly_charge_templates')
        .select('id, unit_id, name, amount')
        .eq('unit_id', unitId)
        .order('name');

    return (data as List)
        .map(
          (row) =>
              UnitMonthlyChargeTemplate.fromMap(row as Map<String, dynamic>),
        )
        .toList();
  }

  Future<UnitMonthlyChargeTemplate> addChargeTemplate({
    required int unitId,
    required String name,
    required int amount,
    required ApplyChargeChangeMonth applyMonth,
  }) async {
    final created = await _supabase
        .from('unit_monthly_charge_templates')
        .insert({'unit_id': unitId, 'name': name.trim(), 'amount': amount})
        .select('id, unit_id, name, amount')
        .single();

    final template = UnitMonthlyChargeTemplate.fromMap(
      Map<String, dynamic>.from(created),
    );
    await _applyTemplateToMonth(
      template: template,
      month: _monthForApply(applyMonth),
      delete: false,
    );
    return template;
  }

  Future<void> updateChargeTemplate({
    required UnitMonthlyChargeTemplate template,
    required String name,
    required int amount,
    required ApplyChargeChangeMonth applyMonth,
  }) async {
    final updatedName = name.trim();
    await _supabase
        .from('unit_monthly_charge_templates')
        .update({'name': updatedName, 'amount': amount})
        .eq('id', template.id);

    final updated = UnitMonthlyChargeTemplate(
      id: template.id,
      unitId: template.unitId,
      name: updatedName,
      amount: amount,
    );

    await _applyTemplateToMonth(
      template: updated,
      month: _monthForApply(applyMonth),
      delete: false,
    );
  }

  Future<void> deleteChargeTemplate({
    required UnitMonthlyChargeTemplate template,
    required ApplyChargeChangeMonth applyMonth,
  }) async {
    await _supabase
        .from('unit_monthly_charge_templates')
        .delete()
        .eq('id', template.id);

    await _applyTemplateToMonth(
      template: template,
      month: _monthForApply(applyMonth),
      delete: true,
    );
  }

  Future<UnitMonthlyLedger> getUnitMonthlyLedgerForManager({
    required int unitId,
    required DateTime month,
  }) async {
    return _buildLedgerForUnit(unitId: unitId, month: month);
  }

  Future<void> addOneTimeUnitBill({
    required int unitId,
    required DateTime month,
    required String name,
    required int amount,
    int? dueDay,
  }) async {
    if (name.trim().isEmpty) {
      throw Exception('Bill name is required.');
    }
    if (amount <= 0) {
      throw Exception('Bill amount must be greater than zero.');
    }
    final resolvedDueDay = dueDay ?? 28;
    _validateDueDay(resolvedDueDay);

    final manager = await _identity.requireCurrentProfile(
      missingMessage: 'No manager profile is linked to this signed-in user.',
    );
    final dueDate = _buildDueDate(month: month, dueDay: resolvedDueDay);

    final created = await _supabase
        .from('one_time_fees')
        .insert({
          'posted_by': manager.id,
          'target_unit_id': unitId,
          'due_date': dueDate.toIso8601String(),
          'status': 'unpaid',
        })
        .select('id')
        .single();

    await _supabase.from('bills').insert({
      'one_time_fee_id': (created['id'] as num).toInt(),
      'name': name.trim(),
      'amount': amount,
    });
  }

  Future<void> setUnitBillDueDay({
    required int unitId,
    required DateTime month,
    required int dueDay,
  }) async {
    _validateDueDay(dueDay);
    final normalizedMonth = _toMonth(month);
    final dueDate = _buildDueDate(month: normalizedMonth, dueDay: dueDay);
    final monthlyBill = await _getUnitMonthlyBill(
      unitId: unitId,
      month: normalizedMonth,
    );

    if (monthlyBill == null) {
      final billId = await _ensureUnitMonthlyBill(
        unitId: unitId,
        month: normalizedMonth,
        dueDay: dueDay,
      );
      await _supabase
          .from('monthly_bills')
          .update({'due_date': dueDate.toIso8601String()})
          .eq('id', billId);
    } else {
      await _supabase
          .from('monthly_bills')
          .update({'due_date': dueDate.toIso8601String()})
          .eq('id', (monthlyBill['id'] as num).toInt());
    }

    final oneTimeFees = await _getUnitOneTimeFeeRows(
      unitId: unitId,
      month: normalizedMonth,
    );
    if (oneTimeFees.isEmpty) return;

    for (final fee in oneTimeFees) {
      final feeId = (fee['id'] as num?)?.toInt();
      if (feeId == null) continue;
      await _supabase
          .from('one_time_fees')
          .update({'due_date': dueDate.toIso8601String()})
          .eq('id', feeId);
    }
  }

  Future<Map<int, UnitBillPaymentSummary>> getCurrentMonthPaymentSummaries({
    required List<int> unitIds,
  }) async {
    if (unitIds.isEmpty) return const <int, UnitBillPaymentSummary>{};

    final month = _toMonth(DateTime.now());
    final start = DateTime(month.year, month.month, 1);
    final next = DateTime(month.year, month.month + 1, 1);
    final summaries = {
      for (final unitId in unitIds)
        unitId: UnitBillPaymentSummary.empty(unitId: unitId, month: month),
    };

    final monthlyRows = await _supabase
        .from('monthly_bills')
        .select(
          'id, target_unit_id, due_date, '
          'bills!bills_monthly_bill_id_fkey(amount), '
          'payments!payments_monthly_bill_id_fkey(amount, status)',
        )
        .inFilter('target_unit_id', unitIds)
        .isFilter('received_by', null)
        .gte('due_date', start.toIso8601String())
        .lt('due_date', next.toIso8601String());

    final oneTimeRows = await _supabase
        .from('one_time_fees')
        .select(
          'id, target_unit_id, due_date, '
          'bills!bills_one_time_fee_id_fkey(amount), '
          'payments!payments_one_time_fee_id_fkey(amount, status)',
        )
        .inFilter('target_unit_id', unitIds)
        .isFilter('received_by', null)
        .gte('due_date', start.toIso8601String())
        .lt('due_date', next.toIso8601String());

    _accumulatePaymentSummaries(
      rows: monthlyRows as List,
      summaries: summaries,
      month: month,
    );
    _accumulatePaymentSummaries(
      rows: oneTimeRows as List,
      summaries: summaries,
      month: month,
    );

    return summaries;
  }

  Future<void> addManagerUnitPayment({
    required int unitId,
    required DateTime month,
    required String paidByResidentId,
    required int amount,
    required String paymentMethod,
  }) async {
    if (amount <= 0) {
      throw Exception('Payment amount must be greater than zero.');
    }
    if (paidByResidentId.trim().isEmpty) {
      throw Exception('Select who paid before saving payment.');
    }
    if (paymentMethod.trim().isEmpty) {
      throw Exception('Select payment method.');
    }

    final manager = await _identity.requireCurrentProfile(
      missingMessage: 'No manager profile is linked to this signed-in user.',
    );
    final targets = await _getUnitAccountabilityTargets(
      unitId: unitId,
      month: month,
    );
    final totalRemaining = targets.fold<int>(
      0,
      (sum, target) => sum + target.remainingAmount,
    );

    if (targets.isEmpty || totalRemaining <= 0) {
      throw Exception('No unit bill has been assigned for this month.');
    }

    if (amount > totalRemaining) {
      throw Exception('Payment cannot exceed the remaining unit balance.');
    }

    var remainingPayment = amount;
    for (final target in targets) {
      if (remainingPayment <= 0) break;
      final appliedAmount = remainingPayment.clamp(0, target.remainingAmount);
      if (appliedAmount <= 0) continue;

      await _supabase.from('payments').insert({
        'monthly_bill_id': target.isMonthly ? target.id : null,
        'one_time_fee_id': target.isMonthly ? null : target.id,
        'paid_by': paidByResidentId,
        'validated_by': manager.id,
        'amount': appliedAmount,
        'status': 'completed',
        'remark': 'Recorded by manager | Method: ${paymentMethod.trim()}',
      });

      await _updateAccountabilityStatus(
        target: target,
        additionalPaidAmount: appliedAmount,
      );
      remainingPayment -= appliedAmount;
    }
  }

  Future<void> submitResidentUnitPayment({
    required DateTime month,
    required int amount,
    required String proofUrl,
    String? remark,
  }) async {
    final profile = await _identity.requireCurrentProfile(
      missingMessage: 'No resident profile is linked to this signed-in user.',
    );
    if (amount <= 0) {
      throw Exception('Payment amount must be greater than zero.');
    }
    if (proofUrl.trim().isEmpty) {
      throw Exception('Proof or reference is required.');
    }

    final unitId = await _getResidentUnitId(profile.id);
    if (unitId == null) {
      throw Exception('No unit is linked to this resident profile.');
    }

    final targets = await _getUnitAccountabilityTargets(
      unitId: unitId,
      month: month,
    );
    final payableAmount = targets.fold<int>(
      0,
      (sum, target) =>
          sum +
          (target.remainingAmount - target.pendingAmount).clamp(
            0,
            target.remainingAmount,
          ),
    );

    if (targets.isEmpty || payableAmount <= 0) {
      throw Exception('No payable unit bill is available for this month.');
    }
    if (amount > payableAmount) {
      throw Exception('Payment cannot exceed the remaining unit balance.');
    }

    var remainingPayment = amount;
    int? firstCreatedPaymentId;
    for (final target in targets) {
      if (remainingPayment <= 0) break;
      final targetPayable = (target.remainingAmount - target.pendingAmount)
          .clamp(0, target.remainingAmount);
      final appliedAmount = remainingPayment.clamp(0, targetPayable);
      if (appliedAmount <= 0) continue;

      final inserted = await _supabase
          .from('payments')
          .insert({
            'monthly_bill_id': target.isMonthly ? target.id : null,
            'one_time_fee_id': target.isMonthly ? null : target.id,
            'paid_by': profile.id,
            'amount': appliedAmount,
            'status': 'pending',
            'proof_url': proofUrl.trim(),
            'remark': remark?.trim(),
          })
          .select('id')
          .single();

      firstCreatedPaymentId ??= (inserted['id'] as num?)?.toInt();

      remainingPayment -= appliedAmount;
    }

    if (firstCreatedPaymentId != null) {
      await _pushDispatcher.dispatchPaymentSubmitted(
        paymentId: firstCreatedPaymentId,
        residentId: profile.id,
      );
    }
  }

  Future<UnitMonthlyLedger> getUnitMonthlyLedgerForResident({
    required DateTime month,
  }) async {
    final profile = await _identity.requireCurrentProfile(
      missingMessage: 'No resident profile is linked to this signed-in user.',
    );

    final unitId = await _getResidentUnitId(profile.id);
    if (unitId == null) {
      return _emptyLedger(month);
    }

    return _buildLedgerForUnit(unitId: unitId, month: month);
  }

  Future<void> _applyTemplateToMonth({
    required UnitMonthlyChargeTemplate template,
    required DateTime month,
    required bool delete,
  }) async {
    final billId = await _ensureUnitMonthlyBill(
      unitId: template.unitId,
      month: month,
    );

    if (delete) {
      await _supabase
          .from('bills')
          .delete()
          .eq('monthly_bill_id', billId)
          .eq('unit_template_id', template.id);
      return;
    }

    final existing = await _supabase
        .from('bills')
        .select('id')
        .eq('monthly_bill_id', billId)
        .eq('unit_template_id', template.id)
        .maybeSingle();

    if (existing == null) {
      await _supabase.from('bills').insert({
        'monthly_bill_id': billId,
        'unit_template_id': template.id,
        'name': template.name,
        'amount': template.amount,
      });
      return;
    }

    await _supabase
        .from('bills')
        .update({'name': template.name, 'amount': template.amount})
        .eq('id', existing['id']);
  }

  Future<int> _ensureUnitMonthlyBill({
    required int unitId,
    required DateTime month,
    int? dueDay,
  }) async {
    final row = await _getUnitMonthlyBill(unitId: unitId, month: month);
    if (row != null) {
      return (row['id'] as num).toInt();
    }

    final profile = await _identity.requireCurrentProfile(
      missingMessage: 'No manager profile is linked to this signed-in user.',
    );

    final dueDate = _buildDueDate(month: month, dueDay: dueDay ?? 28);

    final created = await _supabase
        .from('monthly_bills')
        .insert({
          'posted_by': profile.id,
          'target_unit_id': unitId,
          'due_date': dueDate.toIso8601String(),
          'status': 'unpaid',
        })
        .select('id')
        .single();

    return (created['id'] as num).toInt();
  }

  Future<Map<String, dynamic>?> _getUnitMonthlyBill({
    required int unitId,
    required DateTime month,
  }) async {
    final start = DateTime(month.year, month.month, 1);
    final next = DateTime(month.year, month.month + 1, 1);

    final rows = await _supabase
        .from('monthly_bills')
        .select(
          'id, due_date, status, '
          'bills!bills_monthly_bill_id_fkey(name, amount, unit_template_id), '
          'payments!payments_monthly_bill_id_fkey(id, amount, status, created_at, paid_by)',
        )
        .eq('target_unit_id', unitId)
        .isFilter('received_by', null)
        .gte('due_date', start.toIso8601String())
        .lt('due_date', next.toIso8601String())
        .limit(1);

    final list = List<dynamic>.from(rows);
    if (list.isEmpty) return null;
    return Map<String, dynamic>.from(list.first as Map);
  }

  Future<List<Map<String, dynamic>>> _getUnitOneTimeFeeRows({
    required int unitId,
    required DateTime month,
  }) async {
    final start = DateTime(month.year, month.month, 1);
    final next = DateTime(month.year, month.month + 1, 1);

    final rows = await _supabase
        .from('one_time_fees')
        .select(
          'id, due_date, status, '
          'bills!bills_one_time_fee_id_fkey(name, amount), '
          'payments!payments_one_time_fee_id_fkey(id, amount, status, created_at, paid_by)',
        )
        .eq('target_unit_id', unitId)
        .isFilter('received_by', null)
        .gte('due_date', start.toIso8601String())
        .lt('due_date', next.toIso8601String());

    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<int?> _getResidentUnitId(String residentId) async {
    final resident = await _supabase
        .from('residents')
        .select('unit_id')
        .eq('id', residentId)
        .maybeSingle();
    final unitIdValue = resident?['unit_id'];
    if (unitIdValue == null) return null;
    return unitIdValue is int ? unitIdValue : int.parse(unitIdValue.toString());
  }

  Future<UnitMonthlyLedger> _buildLedgerForUnit({
    required int unitId,
    required DateTime month,
  }) async {
    final monthlyBill = await _getUnitMonthlyBill(unitId: unitId, month: month);
    final oneTimeFees = await _getUnitOneTimeFeeRows(
      unitId: unitId,
      month: month,
    );
    if (monthlyBill == null && oneTimeFees.isEmpty) {
      return _emptyLedger(month);
    }

    final rows = <_UnitAccountabilityRow>[
      if (monthlyBill != null)
        _UnitAccountabilityRow.fromMap(monthlyBill, isMonthly: true),
      ...oneTimeFees.map(
        (row) => _UnitAccountabilityRow.fromMap(row, isMonthly: false),
      ),
    ];

    final charges = rows.expand((row) {
      return row.lineItems.map(
        (item) => UnitLedgerCharge(
          name: (item['name'] ?? '').toString(),
          amount: (item['amount'] as num?)?.toInt() ?? 0,
          isOneTime: !row.isMonthly,
        ),
      );
    }).toList();
    final paymentRows = rows.expand((row) => row.paymentRows).toList();

    final residentIds = paymentRows
        .map((row) => row['paid_by']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final residentNameById = <String, String>{};
    if (residentIds.isNotEmpty) {
      final profiles = await _supabase
          .from('profiles')
          .select('id, first_name, last_name')
          .inFilter('id', residentIds);
      for (final row in profiles as List) {
        final profile = row as Map<String, dynamic>;
        final first = (profile['first_name'] ?? '').toString().trim();
        final last = (profile['last_name'] ?? '').toString().trim();
        final fullName = [
          first,
          last,
        ].where((part) => part.isNotEmpty).join(' ');
        residentNameById[profile['id'].toString()] = fullName.isEmpty
            ? 'Resident'
            : fullName;
      }
    }

    final completedPayments =
        paymentRows
            .where((row) => (row['status'] ?? '').toString() == 'completed')
            .toList()
          ..sort((a, b) {
            final aDate =
                DateTime.tryParse((a['created_at'] ?? '').toString()) ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final bDate =
                DateTime.tryParse((b['created_at'] ?? '').toString()) ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return aDate.compareTo(bDate);
          });

    final paymentEntries = completedPayments.map((row) {
      final paidBy = (row['paid_by'] ?? '').toString();
      final createdAt =
          DateTime.tryParse((row['created_at'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return UnitPaymentEntry(
        residentName: residentNameById[paidBy] ?? 'Resident',
        paidAt: createdAt,
        amount: (row['amount'] as num?)?.toInt() ?? 0,
      );
    }).toList();

    final totalAmount = charges.fold<int>(
      0,
      (sum, charge) => sum + charge.amount,
    );
    final paidAmount = paymentEntries.fold<int>(
      0,
      (sum, payment) => sum + payment.amount,
    );
    final pendingAmount = rows.fold<int>(
      0,
      (sum, row) => sum + row.pendingAmount,
    );
    final remainingAmount = (totalAmount - paidAmount).clamp(0, totalAmount);

    final dueDate = rows.fold<DateTime>(
      DateTime(
        month.year,
        month.month + 1,
        1,
      ).subtract(const Duration(days: 1)),
      (current, row) => row.dueDate.isAfter(current) ? current : row.dueDate,
    );

    final status = _deriveStatus(
      totalAmount: totalAmount,
      remainingAmount: remainingAmount,
      dueDate: dueDate,
    );

    return UnitMonthlyLedger(
      month: DateTime(month.year, month.month, 1),
      dueDate: dueDate,
      hasAssignedBill: totalAmount > 0,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      pendingAmount: pendingAmount,
      remainingAmount: remainingAmount,
      status: status,
      charges: charges,
      payments: paymentEntries,
    );
  }

  UnitMonthlyLedger _emptyLedger(DateTime month) {
    final dueDate = DateTime(
      month.year,
      month.month + 1,
      1,
    ).subtract(const Duration(days: 1));
    return UnitMonthlyLedger(
      month: DateTime(month.year, month.month, 1),
      dueDate: dueDate,
      hasAssignedBill: false,
      totalAmount: 0,
      paidAmount: 0,
      pendingAmount: 0,
      remainingAmount: 0,
      status: 'unpaid',
      charges: const [],
      payments: const [],
    );
  }

  void _accumulatePaymentSummaries({
    required List rows,
    required Map<int, UnitBillPaymentSummary> summaries,
    required DateTime month,
  }) {
    for (final row in rows) {
      final map = Map<String, dynamic>.from(row as Map);
      final unitId = (map['target_unit_id'] as num?)?.toInt();
      if (unitId == null || !summaries.containsKey(unitId)) continue;

      final existing =
          summaries[unitId] ??
          UnitBillPaymentSummary.empty(unitId: unitId, month: month);
      final account = _UnitAccountabilityRow.fromMap(map, isMonthly: true);
      final dueDate = account.dueDate.isBefore(existing.dueDate)
          ? account.dueDate
          : existing.dueDate;

      summaries[unitId] = UnitBillPaymentSummary(
        unitId: unitId,
        month: month,
        dueDate: dueDate,
        hasAssignedBill: existing.hasAssignedBill || account.totalAmount > 0,
        totalAmount: existing.totalAmount + account.totalAmount,
        paidAmount: existing.paidAmount + account.paidAmount,
      );
    }
  }

  Future<List<_UnitAccountabilityRow>> _getUnitAccountabilityTargets({
    required int unitId,
    required DateTime month,
  }) async {
    final monthlyBill = await _getUnitMonthlyBill(unitId: unitId, month: month);
    final oneTimeFees = await _getUnitOneTimeFeeRows(
      unitId: unitId,
      month: month,
    );
    final targets =
        <_UnitAccountabilityRow>[
          if (monthlyBill != null)
            _UnitAccountabilityRow.fromMap(monthlyBill, isMonthly: true),
          ...oneTimeFees.map(
            (row) => _UnitAccountabilityRow.fromMap(row, isMonthly: false),
          ),
        ]..sort((a, b) {
          final dueCompare = a.dueDate.compareTo(b.dueDate);
          if (dueCompare != 0) return dueCompare;
          if (a.isMonthly == b.isMonthly) return a.id.compareTo(b.id);
          return a.isMonthly ? -1 : 1;
        });

    return targets
        .where((target) => target.totalAmount > 0 && target.remainingAmount > 0)
        .toList();
  }

  Future<void> _updateAccountabilityStatus({
    required _UnitAccountabilityRow target,
    required int additionalPaidAmount,
  }) async {
    final paidAmount = target.paidAmount + additionalPaidAmount;
    final remainingAmount = (target.totalAmount - paidAmount).clamp(
      0,
      target.totalAmount,
    );
    final status = _deriveStatus(
      totalAmount: target.totalAmount,
      remainingAmount: remainingAmount,
      dueDate: target.dueDate,
    );
    final table = target.isMonthly ? 'monthly_bills' : 'one_time_fees';
    await _supabase.from(table).update({'status': status}).eq('id', target.id);
  }

  String _deriveStatus({
    required int totalAmount,
    required int remainingAmount,
    required DateTime dueDate,
  }) {
    if (totalAmount <= 0) return 'unpaid';
    if (remainingAmount <= 0) return 'paid';
    final today = DateTime.now();
    final currentDay = DateTime(today.year, today.month, today.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    if (dueDay.isBefore(currentDay)) return 'overdue';
    if (remainingAmount < totalAmount) return 'partial';
    return 'unpaid';
  }

  DateTime _monthForApply(ApplyChargeChangeMonth month) {
    final now = DateTime.now();
    if (month == ApplyChargeChangeMonth.currentMonth) {
      return DateTime(now.year, now.month, 1);
    }
    return DateTime(now.year, now.month + 1, 1);
  }

  DateTime _toMonth(DateTime date) => DateTime(date.year, date.month, 1);

  DateTime _buildDueDate({required DateTime month, required int dueDay}) {
    _validateDueDay(dueDay);
    final normalized = _toMonth(month);
    return DateTime(normalized.year, normalized.month, dueDay);
  }

  void _validateDueDay(int dueDay) {
    if (dueDay < 1 || dueDay > 28) {
      throw Exception('Due date must be between 1 and 28.');
    }
  }
}

class _UnitAccountabilityRow {
  const _UnitAccountabilityRow({
    required this.id,
    required this.isMonthly,
    required this.dueDate,
    required this.lineItems,
    required this.paymentRows,
  });

  final int id;
  final bool isMonthly;
  final DateTime dueDate;
  final List<Map<String, dynamic>> lineItems;
  final List<Map<String, dynamic>> paymentRows;

  int get totalAmount => lineItems.fold<int>(
    0,
    (sum, row) => sum + ((row['amount'] as num?)?.toInt() ?? 0),
  );

  int get paidAmount => paymentRows
      .where((row) => row['status']?.toString() == 'completed')
      .fold<int>(
        0,
        (sum, row) => sum + ((row['amount'] as num?)?.toInt() ?? 0),
      );

  int get pendingAmount => paymentRows
      .where((row) => row['status']?.toString() == 'pending')
      .fold<int>(
        0,
        (sum, row) => sum + ((row['amount'] as num?)?.toInt() ?? 0),
      );

  int get remainingAmount => (totalAmount - paidAmount).clamp(0, totalAmount);

  factory _UnitAccountabilityRow.fromMap(
    Map<String, dynamic> map, {
    required bool isMonthly,
  }) {
    final fallbackDueDate = DateTime.now();
    return _UnitAccountabilityRow(
      id: (map['id'] as num).toInt(),
      isMonthly: isMonthly,
      dueDate:
          DateTime.tryParse((map['due_date'] ?? '').toString()) ??
          fallbackDueDate,
      lineItems: (map['bills'] as List? ?? const [])
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(),
      paymentRows: (map['payments'] as List? ?? const [])
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(),
    );
  }
}

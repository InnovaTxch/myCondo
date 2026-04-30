import 'package:mycondo/data/models/resident.dart';
import 'package:mycondo/data/models/manager/announcement_models.dart';
import 'package:mycondo/data/models/manager/resident_bill_group.dart';
import 'package:mycondo/data/models/unit.dart';
import 'package:mycondo/data/repositories/manager/resident_bill_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResidentService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ResidentBillRepository _billRepository = ResidentBillRepository.instance;

  Future<ResidentDashboardData> fetchDashboardData() async {
    final context = await _requireResidentContext();
    final bills = await _billRepository.getBillsForResident(context.id);
    final announcements = await fetchAnnouncementsForResident();

    final openBills = bills.where((bill) => !bill.isPaid).toList();
    final overdueBills = openBills.where((bill) {
      final today = DateTime.now();
      final dueDay = DateTime(bill.dueDate.year, bill.dueDate.month, bill.dueDate.day);
      final currentDay = DateTime(today.year, today.month, today.day);
      return dueDay.isBefore(currentDay);
    }).toList();

    return ResidentDashboardData(
      firstName: context.firstName,
      unitName: context.unitName,
      openBillsCount: openBills.length,
      overdueBillsCount: overdueBills.length,
      outstandingAmount: openBills.fold<int>(
        0,
        (total, bill) => total + bill.outstandingAmount,
      ),
      nextDueDate: _nextDueDate(openBills),
      latestAnnouncement: _pickHighlightedAnnouncement(announcements),
      openBills: openBills,
    );
  }

  Future<List<Announcement>> fetchAnnouncementsForResident() async {
    final context = await _requireResidentContext();

    final data = await _supabase
        .from('announcements')
        .select()
        .eq('condo_id', context.condoId)
        .order('created_at', ascending: false);

    return (data as List)
        .map((json) => Announcement.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<ResidentBillGroup>> fetchBillsForCurrentResident() async {
    final context = await _requireResidentContext();
    return _billRepository.getBillsForResident(context.id);
  }

  Future<void> submitPayment({
    required ResidentBillGroup bill,
    required int amount,
    required String proofUrl,
    String? remark,
  }) async {
    final context = await _requireResidentContext();
    if (amount <= 0) throw Exception('Payment must be greater than zero.');
    if (amount > bill.outstandingAmount) {
      throw Exception('Payment cannot exceed the outstanding bill amount.');
    }

    final payment = <String, dynamic>{
      'paid_by': context.id,
      'amount': amount,
      'status': 'pending',
      'proof_url': proofUrl.trim(),
      'remark': remark?.trim(),
    };

    if (bill.billType == 'Monthly Bill') {
      payment['monthly_bill_id'] = bill.id;
      payment['one_time_fee_id'] = null;
    } else {
      payment['monthly_bill_id'] = null;
      payment['one_time_fee_id'] = bill.id;
    }

    await _supabase.from('payments').insert(payment);
  }

  Future<List<Unit>?> fetchUnitsForManager() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final condoData = await _supabase
          .from('managers')
          .select('condo_id')
          .eq('id', userId)
          .single();

      final int condoId = condoData['condo_id'];
      final List<dynamic> data = await _supabase
          .from('units')
          .select('id, name, residents(id, profiles(first_name))')
          .eq('condo_id', condoId);

      return data.map((unitRow) {
        final List<dynamic> residentRows = unitRow['residents'] ?? [];

        return Unit(
          id: unitRow['id'] as int,
          name: unitRow['name'] as String,
          members: residentRows
              .map(
                (resRow) => Resident(
                  id: resRow['id'] as String,
                  name: resRow['profiles']['first_name'] as String,
                  unitName: unitRow['name'] as String,
                ),
              )
              .toList(),
        );
      }).toList();
    } catch (e) {
      print("Error fetching units: $e");
      return [];
    }
  }

  DateTime? _nextDueDate(List<ResidentBillGroup> bills) {
    if (bills.isEmpty) return null;
    final sorted = [...bills]..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return sorted.first.dueDate;
  }

  Announcement? _pickHighlightedAnnouncement(List<Announcement> announcements) {
    if (announcements.isEmpty) return null;
    for (final ann in announcements) {
      if (ann.category == 'urgent') return ann;
    }
    for (final ann in announcements) {
      if (ann.category == 'reminder') return ann;
    }
    return announcements.first;
  }

  Future<_ResidentContext> _requireResidentContext() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No authenticated resident user found.');
    }

    final resident = await _supabase
        .from('residents')
        .select('id, unit_id, units(name, condo_id), profiles(first_name)')
        .eq('id', userId)
        .single();

    final unit = resident['units'] as Map<String, dynamic>? ?? {};
    final profile = resident['profiles'] as Map<String, dynamic>? ?? {};
    final condoIdValue = unit['condo_id'];

    return _ResidentContext(
      id: resident['id'] as String? ?? userId,
      firstName: (profile['first_name'] as String? ?? '').trim(),
      unitName: (unit['name'] as String? ?? '').trim(),
      condoId: condoIdValue is int ? condoIdValue : int.parse(condoIdValue.toString()),
    );
  }
}

class ResidentDashboardData {
  const ResidentDashboardData({
    required this.firstName,
    required this.unitName,
    required this.openBillsCount,
    required this.overdueBillsCount,
    required this.outstandingAmount,
    required this.nextDueDate,
    required this.latestAnnouncement,
    required this.openBills,
  });

  final String firstName;
  final String unitName;
  final int openBillsCount;
  final int overdueBillsCount;
  final int outstandingAmount;
  final DateTime? nextDueDate;
  final Announcement? latestAnnouncement;
  final List<ResidentBillGroup> openBills;
}

class _ResidentContext {
  const _ResidentContext({
    required this.id,
    required this.firstName,
    required this.unitName,
    required this.condoId,
  });

  final String id;
  final String firstName;
  final String unitName;
  final int condoId;
}

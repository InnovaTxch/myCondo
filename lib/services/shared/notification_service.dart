import 'dart:async';

import 'package:mycondo/data/repositories/auth/profile_identity_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ProfileIdentityService _identity = ProfileIdentityService();

  Future<ManagerNotificationSnapshot> getManagerInitialSnapshot() async {
    final profile = await _identity.requireCurrentProfile();
    final residentIds = await _getResidentIdsForManager(profile.id);
    final condoId = await _getManagerCondoId(profile.id);

    final hasPaymentNotifications =
        residentIds.isNotEmpty && await _hasPendingPayments(residentIds);
    final hasMaintenanceNotifications =
        condoId != null && await _hasOpenMaintenanceRequestsForManager(condoId);

    return ManagerNotificationSnapshot(
      hasPaymentNotifications: hasPaymentNotifications,
      hasMaintenanceNotifications: hasMaintenanceNotifications,
    );
  }

  Future<ResidentNotificationSnapshot> getResidentInitialSnapshot() async {
    final profile = await _identity.requireCurrentProfile();

    final hasPaymentNotifications = await _hasUnseenResidentPaymentDecisions(
      profile.id,
    );
    final hasMaintenanceNotifications = await _hasNonPendingResidentMaintenance(
      profile.id,
    );

    return ResidentNotificationSnapshot(
      hasPaymentNotifications: hasPaymentNotifications,
      hasMaintenanceNotifications: hasMaintenanceNotifications,
      hasAnnouncementNotifications: false,
    );
  }

  /// For the MANAGER: emits popup messages for resident-side actions.
  Stream<String> managerActionPopupsStream() async* {
    final profile = await _identity.requireCurrentProfile();
    final residentIds = await _getResidentIdsForManager(profile.id);
    final condoId = await _getManagerCondoId(profile.id);

    if (residentIds.isEmpty && condoId == null) return;

    final controller = StreamController<String>();
    final subscriptions = <StreamSubscription<dynamic>>[];
    final residentIdSet = residentIds.toSet();

    final knownPendingPaymentIds = residentIds.isEmpty
        ? <int>{}
        : await _fetchPendingPaymentIds(residentIds);
    final knownMaintenanceRequestIds = condoId == null
        ? <int>{}
        : await _fetchMaintenanceRequestIdsForCondo(condoId);

    if (residentIds.isNotEmpty) {
      subscriptions.add(
        _supabase
            .from('payments')
            .stream(primaryKey: ['id'])
            .eq('status', 'pending')
            .listen((rows) {
              final currentIds = <int>{};
              for (final raw in rows as List<dynamic>) {
                final row = raw as Map<String, dynamic>;
                final paidBy = (row['paid_by'] ?? '').toString();
                if (!residentIdSet.contains(paidBy)) continue;

                final id = _asInt(row['id']);
                if (id != null) currentIds.add(id);
              }
              final newCount = currentIds
                  .difference(knownPendingPaymentIds)
                  .length;

              knownPendingPaymentIds
                ..clear()
                ..addAll(currentIds);

              if (newCount <= 0) return;
              controller.add(
                newCount == 1
                    ? 'New payment submitted for approval.'
                    : '$newCount new payments submitted for approval.',
              );
            }),
      );
    }

    if (condoId != null) {
      subscriptions.add(
        _supabase
            .from('maintenance_requests')
            .stream(primaryKey: ['id'])
            .eq('condo_id', condoId)
            .listen((rows) {
              final currentIds = _extractIntIdSet(rows);
              final newCount = currentIds
                  .difference(knownMaintenanceRequestIds)
                  .length;

              knownMaintenanceRequestIds
                ..clear()
                ..addAll(currentIds);

              if (newCount <= 0) return;
              controller.add(
                newCount == 1
                    ? 'New maintenance request submitted.'
                    : '$newCount new maintenance requests submitted.',
              );
            }),
      );
    }

    try {
      yield* controller.stream;
    } finally {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
      await controller.close();
    }
  }

  /// For the RESIDENT: emits popup messages for manager-side updates.
  Stream<String> residentActionPopupsStream() async* {
    final profile = await _identity.requireCurrentProfile();
    final condoId = await _getResidentCondoId(profile.id);
    if (condoId == null) return;

    final controller = StreamController<String>();
    final subscriptions = <StreamSubscription<dynamic>>[];

    final knownPaymentStatuses = await _fetchResidentPaymentStatuses(
      profile.id,
    );
    final knownMaintenanceStatuses = await _fetchResidentMaintenanceStatuses(
      profile.id,
    );
    final knownAnnouncementIds = await _fetchAnnouncementIdsForCondo(condoId);

    subscriptions.add(
      _supabase
          .from('payments')
          .stream(primaryKey: ['id'])
          .eq('paid_by', profile.id)
          .listen((rows) {
            final currentStatuses = <int, String>{};
            var approvedCount = 0;
            var rejectedCount = 0;

            for (final raw in rows as List<dynamic>) {
              final row = raw as Map<String, dynamic>;
              final id = _asInt(row['id']);
              if (id == null) continue;

              final status = _normalizedStatus(row['status']);
              final previous = knownPaymentStatuses[id];

              final becameApproved =
                  status == 'completed' &&
                  (previous == null || previous != 'completed');
              final becameRejected =
                  status == 'rejected' &&
                  (previous == null || previous != 'rejected');

              if (becameApproved) approvedCount += 1;
              if (becameRejected) rejectedCount += 1;
              currentStatuses[id] = status;
            }

            knownPaymentStatuses
              ..clear()
              ..addAll(currentStatuses);

            final updates = approvedCount + rejectedCount;
            if (updates <= 0) return;

            if (approvedCount > 0 && rejectedCount > 0) {
              controller.add(
                '$approvedCount payment(s) approved, $rejectedCount payment(s) rejected.',
              );
              return;
            }

            if (approvedCount > 0) {
              controller.add(
                approvedCount == 1
                    ? 'Your payment was approved.'
                    : '$approvedCount of your payments were approved.',
              );
              return;
            }

            controller.add(
              rejectedCount == 1
                  ? 'A payment was rejected. Check the reason in Payments.'
                  : '$rejectedCount payments were rejected. Check the reasons in Payments.',
            );
          }),
    );

    subscriptions.add(
      _supabase
          .from('maintenance_requests')
          .stream(primaryKey: ['id'])
          .eq('resident_id', profile.id)
          .listen((rows) {
            final currentStatuses = <int, String>{};
            var changedCount = 0;

            for (final raw in rows as List<dynamic>) {
              final row = raw as Map<String, dynamic>;
              final id = _asInt(row['id']);
              if (id == null) continue;

              final status = _normalizedStatus(row['status']);
              final previous = knownMaintenanceStatuses[id];

              final changedByManager =
                  previous != null && previous != status && status.isNotEmpty;
              final newNonPending =
                  previous == null && status.isNotEmpty && status != 'pending';

              if (changedByManager || newNonPending) {
                changedCount += 1;
              }

              currentStatuses[id] = status;
            }

            knownMaintenanceStatuses
              ..clear()
              ..addAll(currentStatuses);

            if (changedCount <= 0) return;

            controller.add(
              changedCount == 1
                  ? 'Your maintenance request has a new status update.'
                  : '$changedCount maintenance requests have status updates.',
            );
          }),
    );

    subscriptions.add(
      _supabase
          .from('announcements')
          .stream(primaryKey: ['id'])
          .eq('condo_id', condoId)
          .listen((rows) {
            final currentIds = <int>{};
            final titleById = <int, String>{};

            for (final raw in rows as List<dynamic>) {
              final row = raw as Map<String, dynamic>;
              if (!_isAnnouncementVisibleNow(row)) continue;
              final id = _asInt(row['id']);
              if (id == null) continue;

              currentIds.add(id);
              titleById[id] = (row['title'] ?? '').toString().trim();
            }

            final newIds = currentIds.difference(knownAnnouncementIds);
            knownAnnouncementIds
              ..clear()
              ..addAll(currentIds);

            if (newIds.isEmpty) return;

            if (newIds.length == 1) {
              final onlyId = newIds.first;
              final title = titleById[onlyId];
              if (title != null && title.isNotEmpty) {
                controller.add('New announcement: $title');
                return;
              }
            }

            controller.add(
              newIds.length == 1
                  ? 'A new announcement was posted.'
                  : '${newIds.length} new announcements were posted.',
            );
          }),
    );

    try {
      yield* controller.stream;
    } finally {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
      await controller.close();
    }
  }

  Future<List<String>> _getResidentIdsForManager(String managerId) async {
    final manager = await _supabase
        .from('managers')
        .select('condo_id')
        .eq('id', managerId)
        .maybeSingle();

    if (manager == null) return [];

    final units = await _supabase
        .from('units')
        .select('id')
        .eq('condo_id', manager['condo_id']);

    final unitIds = (units as List)
        .map((u) => (u as Map<String, dynamic>)['id'])
        .toList();

    if (unitIds.isEmpty) return [];

    final residents = await _supabase
        .from('residents')
        .select('id')
        .inFilter('unit_id', unitIds)
        .eq('status', 'active');

    return (residents as List)
        .map((r) => (r as Map<String, dynamic>)['id'].toString())
        .toList();
  }

  Future<int?> _getManagerCondoId(String managerId) async {
    final manager = await _supabase
        .from('managers')
        .select('condo_id')
        .eq('id', managerId)
        .maybeSingle();

    if (manager == null) return null;
    return _asInt(manager['condo_id']);
  }

  Future<int?> _getResidentCondoId(String residentId) async {
    final resident = await _supabase
        .from('residents')
        .select('unit_id')
        .eq('id', residentId)
        .maybeSingle();
    if (resident == null) return null;

    final unitId = resident['unit_id'];
    if (unitId == null) return null;

    final unit = await _supabase
        .from('units')
        .select('condo_id')
        .eq('id', unitId)
        .maybeSingle();
    if (unit == null) return null;

    return _asInt(unit['condo_id']);
  }

  Future<Set<int>> _fetchPendingPaymentIds(List<String> residentIds) async {
    if (residentIds.isEmpty) return <int>{};

    final rows = await _supabase
        .from('payments')
        .select('id')
        .inFilter('paid_by', residentIds)
        .eq('status', 'pending');

    return _extractIntIdSet(rows);
  }

  Future<bool> _hasPendingPayments(List<String> residentIds) async {
    final rows = await _supabase
        .from('payments')
        .select('id')
        .inFilter('paid_by', residentIds)
        .eq('status', 'pending')
        .limit(1);

    return (rows as List<dynamic>).isNotEmpty;
  }

  Future<bool> _hasOpenMaintenanceRequestsForManager(int condoId) async {
    final rows = await _supabase
        .from('maintenance_requests')
        .select('id')
        .eq('condo_id', condoId)
        .inFilter('status', ['pending', 'in_progress'])
        .limit(1);

    return (rows as List<dynamic>).isNotEmpty;
  }

  Future<bool> _hasUnseenResidentPaymentDecisions(String residentId) async {
    final rows = await _supabase
        .from('payments')
        .select('id')
        .eq('paid_by', residentId)
        .inFilter('status', ['completed', 'rejected'])
        .eq('payment_seen_by_resident', false)
        .limit(1);

    return (rows as List<dynamic>).isNotEmpty;
  }

  Future<bool> _hasNonPendingResidentMaintenance(String residentId) async {
    final rows = await _supabase
        .from('maintenance_requests')
        .select('id')
        .eq('resident_id', residentId)
        .inFilter('status', ['in_progress', 'resolved', 'cancelled'])
        .limit(1);

    return (rows as List<dynamic>).isNotEmpty;
  }

  Future<Set<int>> _fetchMaintenanceRequestIdsForCondo(int condoId) async {
    final rows = await _supabase
        .from('maintenance_requests')
        .select('id')
        .eq('condo_id', condoId);
    return _extractIntIdSet(rows);
  }

  Future<Map<int, String>> _fetchResidentPaymentStatuses(
    String residentId,
  ) async {
    final rows = await _supabase
        .from('payments')
        .select('id, status')
        .eq('paid_by', residentId);

    final statuses = <int, String>{};
    for (final raw in rows as List<dynamic>) {
      final row = raw as Map<String, dynamic>;
      final id = _asInt(row['id']);
      if (id == null) continue;
      statuses[id] = _normalizedStatus(row['status']);
    }
    return statuses;
  }

  Future<Map<int, String>> _fetchResidentMaintenanceStatuses(
    String residentId,
  ) async {
    final rows = await _supabase
        .from('maintenance_requests')
        .select('id, status')
        .eq('resident_id', residentId);

    final statuses = <int, String>{};
    for (final raw in rows as List<dynamic>) {
      final row = raw as Map<String, dynamic>;
      final id = _asInt(row['id']);
      if (id == null) continue;
      statuses[id] = _normalizedStatus(row['status']);
    }
    return statuses;
  }

  Future<Set<int>> _fetchAnnouncementIdsForCondo(int condoId) async {
    final rows = await _supabase
        .from('announcements')
        .select('id, starts_at, ends_at, status')
        .eq('condo_id', condoId);
    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .where(_isAnnouncementVisibleNow)
        .map((row) => _asInt(row['id']))
        .whereType<int>()
        .toSet();
  }

  Set<int> _extractIntIdSet(dynamic rows) {
    return (rows as List<dynamic>)
        .map((raw) => _asInt((raw as Map<String, dynamic>)['id']))
        .whereType<int>()
        .toSet();
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  String _normalizedStatus(dynamic value) {
    return value == null ? '' : value.toString().trim().toLowerCase();
  }

  bool _isAnnouncementVisibleNow(Map<String, dynamic> row) {
    final status = _normalizedStatus(row['status']);
    if (status == 'archived') return false;

    final now = DateTime.now().toUtc();
    final startsAt = _asDateTime(row['starts_at'])?.toUtc();
    if (startsAt != null && startsAt.isAfter(now)) return false;

    final endsAt = _asDateTime(row['ends_at'])?.toUtc();
    if (endsAt != null && !endsAt.isAfter(now)) return false;

    return true;
  }

  DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

class ManagerNotificationSnapshot {
  const ManagerNotificationSnapshot({
    required this.hasPaymentNotifications,
    required this.hasMaintenanceNotifications,
  });

  final bool hasPaymentNotifications;
  final bool hasMaintenanceNotifications;
}

class ResidentNotificationSnapshot {
  const ResidentNotificationSnapshot({
    required this.hasPaymentNotifications,
    required this.hasMaintenanceNotifications,
    required this.hasAnnouncementNotifications,
  });

  final bool hasPaymentNotifications;
  final bool hasMaintenanceNotifications;
  final bool hasAnnouncementNotifications;
}

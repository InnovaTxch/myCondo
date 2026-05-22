import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mycondo/data/repositories/manager/maintenance_requests_service.dart';
import 'package:mycondo/features/shared/widgets/app_states.dart';
import 'package:mycondo/theme/app_theme.dart';
import 'package:mycondo/utils/app_snackbar.dart';

class MaintenanceRequestsPage extends StatefulWidget {
  const MaintenanceRequestsPage({super.key});

  @override
  State<MaintenanceRequestsPage> createState() =>
      _MaintenanceRequestsPageState();
}

class _MaintenanceRequestsPageState extends State<MaintenanceRequestsPage> {
  final _service = ManagerMaintenanceRequestsService();
  late Map<String, Future<List<ManagerMaintenanceRequest>>> _requestsByStatus;

  static const _statusTabs = <String>[
    'pending',
    'in_progress',
    'resolved',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _requestsByStatus = {
      for (final status in _statusTabs) status: _loadRequests(status),
    };
  }

  Future<List<ManagerMaintenanceRequest>> _loadRequests(String status) {
    return _service.fetchRequests(status: status);
  }

  Future<void> _refreshStatus(String status) async {
    final future = _loadRequests(status);
    setState(() => _requestsByStatus[status] = future);
    await future;
  }

  Future<void> _refreshAll() async {
    final updated = {
      for (final status in _statusTabs) status: _loadRequests(status),
    };
    setState(() => _requestsByStatus = updated);
    await Future.wait(updated.values);
  }

  Future<void> _openUpdateSheet(ManagerMaintenanceRequest request) async {
    final update = await showModalBottomSheet<_MaintenanceUpdateResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => _MaintenanceUpdateSheet(
        initialStatus: request.status,
        initialNotes: request.managerNotes,
        statusLabel: _statusLabel,
      ),
    );

    if (update == null) return;

    try {
      await _service.updateRequestStatus(
        requestId: request.id,
        status: update.status,
        managerNotes: update.managerNotes,
      );
      if (!mounted) return;
      context.showAppSnackBar(
        const SnackBar(content: Text('Maintenance request updated.')),
      );
      await _refreshAll();
    } catch (e, st) {
      if (!mounted) return;
      context.showAppError(
        e,
        stackTrace: st,
        fallbackMessage: 'Could not update this maintenance request.',
        debugLabel: 'MaintenanceRequestsPage.updateRequest',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _statusTabs.length,
      child: Scaffold(
        backgroundColor: AppColors.lightBlueBackground,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: const [
                    Text(
                      'Maintenance',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: AppColors.darkText,
                  unselectedLabelColor: AppColors.secondaryText,
                  indicatorColor: AppColors.primaryBlue,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                  padding: EdgeInsets.zero,
                  labelPadding: const EdgeInsets.only(right: 10),
                  tabs: _statusTabs
                      .map(
                        (status) => Tab(
                          child: _StatusCountTab(
                            label: _statusLabel(status),
                            requestsFuture: _requestsByStatus[status]!,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  children: _statusTabs
                      .map(
                        (status) => _RequestsTab(
                          future: _requestsByStatus[status]!,
                          onRefresh: () => _refreshStatus(status),
                          onUpdate: _openUpdateSheet,
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _statusLabel(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized == 'in_progress') return 'In Progress';
    if (normalized.isEmpty) return 'Unknown';
    return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
  }
}

class _StatusCountTab extends StatelessWidget {
  const _StatusCountTab({required this.label, required this.requestsFuture});

  final String label;
  final Future<List<ManagerMaintenanceRequest>> requestsFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ManagerMaintenanceRequest>>(
      future: requestsFuture,
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.length : 0;
        final countLabel = count > 99 ? '99+' : '$count';
        final hasItems = count > 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 6, right: 18, top: 4),
              child: Text(label, textAlign: TextAlign.center),
            ),
            if (hasItems)
              Positioned(
                right: 0,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    countLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RequestsTab extends StatelessWidget {
  const _RequestsTab({
    required this.future,
    required this.onRefresh,
    required this.onUpdate,
  });

  final Future<List<ManagerMaintenanceRequest>> future;
  final Future<void> Function() onRefresh;
  final ValueChanged<ManagerMaintenanceRequest> onUpdate;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: FutureBuilder<List<ManagerMaintenanceRequest>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState();
          }

          if (snapshot.hasError) {
            debugPrint(
              '[MaintenanceRequestsPage.loadRequests] ${snapshot.error}\n${snapshot.stackTrace ?? ''}',
            );
            return AppErrorState(
              message: 'Unable to load maintenance requests.',
              onRetry: onRefresh,
            );
          }

          final requests = snapshot.data ?? const [];
          if (requests.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(
                  height: 420,
                  child: AppEmptyState(
                    icon: Icons.build_circle_outlined,
                    title: 'No requests yet',
                    message: 'Submitted maintenance requests will appear here.',
                    card: false,
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            itemCount: requests.length,
            separatorBuilder: (_, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final request = requests[index];
              return _RequestCard(
                request: request,
                onUpdate: () => onUpdate(request),
              );
            },
          );
        },
      ),
    );
  }
}

class _MaintenanceUpdateResult {
  const _MaintenanceUpdateResult({
    required this.status,
    required this.managerNotes,
  });

  final String status;
  final String managerNotes;
}

class _MaintenanceUpdateSheet extends StatefulWidget {
  const _MaintenanceUpdateSheet({
    required this.initialStatus,
    required this.initialNotes,
    required this.statusLabel,
  });

  final String initialStatus;
  final String initialNotes;
  final String Function(String) statusLabel;

  @override
  State<_MaintenanceUpdateSheet> createState() =>
      _MaintenanceUpdateSheetState();
}

class _MaintenanceUpdateSheetState extends State<_MaintenanceUpdateSheet> {
  static const _updateStatuses = <String>[
    'pending',
    'in_progress',
    'resolved',
    'cancelled',
  ];

  late final TextEditingController _notesController;
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = _updateStatuses.contains(widget.initialStatus)
        ? widget.initialStatus
        : 'pending';
    _notesController = TextEditingController(text: widget.initialNotes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 18,
          bottom: MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Update Maintenance Request',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: _updateStatuses
                    .map(
                      (status) => DropdownMenuItem<String>(
                        value: status,
                        child: Text(widget.statusLabel(status)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedStatus = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Manager Notes',
                  hintText: 'Optional update or resolution details',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      _MaintenanceUpdateResult(
                        status: _selectedStatus,
                        managerNotes: _notesController.text,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save Update'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onUpdate});

  final ManagerMaintenanceRequest request;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final dateLabel = request.createdAt == null
        ? '--'
        : DateFormat('MMM d, yyyy - h:mm a').format(request.createdAt!);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.reporterName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              _StatusChip(status: request.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Room ${request.roomNumber} - ${request.problemType}',
            style: const TextStyle(
              color: Color(0xFF5E6B75),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            request.description,
            style: const TextStyle(color: Color(0xFF2C333A), height: 1.3),
          ),
          if (request.managerNotes.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Manager note: ${request.managerNotes}',
              style: const TextStyle(
                color: Color(0xFF3D4E63),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              _PriorityChip(priority: request.priority),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dateLabel,
                  style: const TextStyle(
                    color: Color(0xFF7A8792),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(onPressed: onUpdate, child: const Text('Update')),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority});

  final String priority;

  @override
  Widget build(BuildContext context) {
    final normalized = priority.trim().toLowerCase();
    final color = switch (normalized) {
      'urgent' => const Color(0xFFD92C2C),
      'high' => const Color(0xFFDE7A13),
      'medium' => const Color(0xFF1A73C8),
      _ => const Color(0xFF4B7A44),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    final color = switch (normalized) {
      'resolved' => const Color(0xFF1F8E3D),
      'in_progress' => const Color(0xFF1A73C8),
      'cancelled' => const Color(0xFF9F3A3A),
      _ => const Color(0xFF9C6A1D),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _MaintenanceRequestsPageState._statusLabel(normalized).toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

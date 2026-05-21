import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mycondo/data/repositories/resident/maintenance_request_service.dart';
import 'package:mycondo/theme/app_theme.dart';

class MaintenanceRequestPage extends StatefulWidget {
  const MaintenanceRequestPage({super.key});

  @override
  State<MaintenanceRequestPage> createState() => _MaintenanceRequestPageState();
}

class _MaintenanceRequestPageState extends State<MaintenanceRequestPage> {
  final _service = MaintenanceRequestService();

  static const _statusTabs = <String>[
    'pending',
    'in_progress',
    'resolved',
    'cancelled',
  ];

  late Map<String, Future<List<MaintenanceRequestRecord>>> _requestsByStatus;

  @override
  void initState() {
    super.initState();
    _requestsByStatus = {
      for (final status in _statusTabs)
        status: _service.fetchMyRequests(status: status),
    };
  }

  Future<void> _refreshRequests(String status) async {
    final future = _service.fetchMyRequests(status: status);
    setState(() => _requestsByStatus[status] = future);
    await future;
  }

  Future<void> _refreshAll() async {
    setState(() {
      _requestsByStatus = {
        for (final status in _statusTabs)
          status: _service.fetchMyRequests(status: status),
      };
    });
    await Future.wait(_requestsByStatus.values);
  }

  Future<void> _openForm() async {
    final created = await Navigator.pushNamed(
      context,
      '/resident-maintenance-request-form',
    );
    if (!mounted || created != true) return;
    await _refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlueBackground,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        backgroundColor: AppColors.darkText,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'Request',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text(
                    'Maintenance',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _ResidentRequestsSection(
              statuses: _statusTabs,
              requestsByStatus: _requestsByStatus,
              onRefreshStatus: _refreshRequests,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResidentRequestsSection extends StatelessWidget {
  const _ResidentRequestsSection({
    required this.statuses,
    required this.requestsByStatus,
    required this.onRefreshStatus,
  });

  final List<String> statuses;
  final Map<String, Future<List<MaintenanceRequestRecord>>> requestsByStatus;
  final Future<void> Function(String status) onRefreshStatus;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: statuses.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.darkText,
            unselectedLabelColor: AppColors.secondaryText,
            indicatorColor: AppColors.primaryBlue,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700),
            padding: const EdgeInsets.only(left: 8),
            labelPadding: const EdgeInsets.only(right: 10),
            tabs: statuses
                .map(
                  (status) => Tab(
                    child: _ResidentStatusCountTab(
                      label: _statusLabel(status),
                      requestsFuture: requestsByStatus[status]!,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 360,
            child: TabBarView(
              children: statuses
                  .map(
                    (status) => _ResidentRequestsTab(
                      future: requestsByStatus[status]!,
                      onRefresh: () => onRefreshStatus(status),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    final normalized = status.trim().toLowerCase();
    if (normalized == 'in_progress') return 'In Progress';
    if (normalized.isEmpty) return 'Unknown';
    return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
  }
}

class _ResidentStatusCountTab extends StatelessWidget {
  const _ResidentStatusCountTab({
    required this.label,
    required this.requestsFuture,
  });

  final String label;
  final Future<List<MaintenanceRequestRecord>> requestsFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MaintenanceRequestRecord>>(
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

class _ResidentRequestsTab extends StatelessWidget {
  const _ResidentRequestsTab({required this.future, required this.onRefresh});

  final Future<List<MaintenanceRequestRecord>> future;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: FutureBuilder<List<MaintenanceRequestRecord>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(
                  height: 300,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ],
            );
          }

          if (snapshot.hasError) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(
                  height: 300,
                  child: Center(
                    child: Text(
                      'Unable to load maintenance requests.',
                      style: TextStyle(color: Color(0xFF8A8A8A)),
                    ),
                  ),
                ),
              ],
            );
          }

          final requests = snapshot.data ?? const [];
          if (requests.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(
                  height: 300,
                  child: Center(
                    child: Text(
                      'No requests yet.',
                      style: TextStyle(color: Color(0xFF8A8A8A)),
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: requests.length,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return _ResidentRequestTile(request: requests[index]);
            },
          );
        },
      ),
    );
  }
}

class _ResidentRequestTile extends StatelessWidget {
  const _ResidentRequestTile({required this.request});

  final MaintenanceRequestRecord request;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (request.status.trim().toLowerCase()) {
      'resolved' => const Color(0xFF1F8E3D),
      'in_progress' => const Color(0xFF1A73C8),
      'cancelled' => const Color(0xFF9F3A3A),
      _ => const Color(0xFF9C6A1D),
    };

    final createdLabel = request.createdAt == null
        ? '--'
        : DateFormat('MMM d, yyyy').format(request.createdAt!.toLocal());

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FCFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2EDF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.problemType,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel(request.status).toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            request.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF55646E), fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            '$createdLabel - ${request.priority.toUpperCase()}',
            style: const TextStyle(
              color: Color(0xFF7A8792),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (request.managerNotes.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Manager note: ${request.managerNotes}',
              style: const TextStyle(
                color: Color(0xFF3D4E63),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    final normalized = status.trim().toLowerCase();
    if (normalized == 'in_progress') return 'In Progress';
    if (normalized.isEmpty) return 'Pending';
    return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
  }
}

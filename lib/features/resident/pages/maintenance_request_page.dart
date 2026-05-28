import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mycondo/data/repositories/resident/maintenance_request_service.dart';
import 'package:mycondo/features/resident/pages/maintenance_request_form_page.dart';
import 'package:mycondo/features/resident/pages/resident_manager_chat_screen.dart';
import 'package:mycondo/features/shared/widgets/page_header.dart';
import 'package:mycondo/theme/app_theme.dart';
import 'package:mycondo/utils/app_snackbar.dart';

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

  Future<void> _openForm({MaintenanceRequestFormPrefill? prefill}) async {
    final created = await Navigator.pushNamed(
      context,
      '/resident-maintenance-request-form',
      arguments: prefill,
    );
    if (!mounted || created != true) return;
    await _refreshAll();
  }

  Future<void> _openManagerChat() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ResidentManagerChatScreen(showBackButton: true),
      ),
    );
  }

  Future<void> _submitFollowUp(MaintenanceRequestRecord request) async {
    final notes = request.managerNotes.trim();
    final description = StringBuffer(
      'Follow-up for request #${request.id} (${request.problemType}).\n',
    );
    if (notes.isNotEmpty) {
      description.write('Manager note: $notes\n');
    }
    description.write('\n');

    await _openForm(
      prefill: MaintenanceRequestFormPrefill(
        priority: request.priority,
        problemType: request.problemType,
        description: description.toString(),
        sourceRequestId: request.id,
        isFollowUp: true,
      ),
    );
  }

  Future<void> _requestAgain(MaintenanceRequestRecord request) async {
    await _openForm(
      prefill: MaintenanceRequestFormPrefill(
        priority: request.priority,
        problemType: request.problemType,
        description: request.description.trim(),
        sourceRequestId: request.id,
      ),
    );
  }

  Future<void> _cancelRequest(MaintenanceRequestRecord request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel request?'),
          content: const Text(
            'This will mark the request as cancelled. You can still submit another request later.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cancel Request'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    try {
      await _service.cancelMyRequest(requestId: request.id);
      if (!mounted) return;
      context.showAppSnackBar(
        const SnackBar(content: Text('Request cancelled.')),
      );
      await _refreshAll();
    } catch (e, st) {
      if (!mounted) return;
      context.showAppError(
        e,
        stackTrace: st,
        fallbackMessage:
            'Could not cancel this request right now. Please try again later.',
        debugLabel: 'MaintenanceRequestPage.cancelRequest',
      );
    }
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
            const AppPageHeader(title: 'Maintenance'),
            const SizedBox(height: 6),
            _ResidentRequestsSection(
              statuses: _statusTabs,
              requestsByStatus: _requestsByStatus,
              onRefreshStatus: _refreshRequests,
              onMessageManager: _openManagerChat,
              onSubmitFollowUp: _submitFollowUp,
              onCancelRequest: _cancelRequest,
              onRequestAgain: _requestAgain,
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
    required this.onMessageManager,
    required this.onSubmitFollowUp,
    required this.onCancelRequest,
    required this.onRequestAgain,
  });

  final List<String> statuses;
  final Map<String, Future<List<MaintenanceRequestRecord>>> requestsByStatus;
  final Future<void> Function(String status) onRefreshStatus;
  final Future<void> Function() onMessageManager;
  final Future<void> Function(MaintenanceRequestRecord request)
  onSubmitFollowUp;
  final Future<void> Function(MaintenanceRequestRecord request) onCancelRequest;
  final Future<void> Function(MaintenanceRequestRecord request) onRequestAgain;

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
                      onMessageManager: onMessageManager,
                      onSubmitFollowUp: onSubmitFollowUp,
                      onCancelRequest: onCancelRequest,
                      onRequestAgain: onRequestAgain,
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
        final count = snapshot.data?.length ?? 0;
        final colors = _countChipColors(label);

        return Padding(
          padding: const EdgeInsets.only(left: 6, right: 2, top: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, textAlign: TextAlign.center),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.foreground,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  ({Color background, Color foreground}) _countChipColors(String label) {
    final normalized = label.trim().toLowerCase();
    if (normalized == 'pending') {
      return (
        background: const Color(0xFFF9ECCE),
        foreground: const Color(0xFF8A5A00),
      );
    }
    if (normalized == 'in progress') {
      return (
        background: const Color(0xFFDDEBFF),
        foreground: const Color(0xFF1A73C8),
      );
    }
    if (normalized == 'resolved') {
      return (
        background: const Color(0xFFDBF2E3),
        foreground: const Color(0xFF1F8E3D),
      );
    }
    if (normalized == 'cancelled') {
      return (
        background: const Color(0xFFF6E2E2),
        foreground: const Color(0xFF9F3A3A),
      );
    }
    return (
      background: const Color(0xFFE9EDF5),
      foreground: const Color(0xFF4E5B70),
    );
  }
}

class _ResidentRequestsTab extends StatelessWidget {
  const _ResidentRequestsTab({
    required this.future,
    required this.onRefresh,
    required this.onMessageManager,
    required this.onSubmitFollowUp,
    required this.onCancelRequest,
    required this.onRequestAgain,
  });

  final Future<List<MaintenanceRequestRecord>> future;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onMessageManager;
  final Future<void> Function(MaintenanceRequestRecord request)
  onSubmitFollowUp;
  final Future<void> Function(MaintenanceRequestRecord request) onCancelRequest;
  final Future<void> Function(MaintenanceRequestRecord request) onRequestAgain;

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
              return _ResidentRequestTile(
                request: requests[index],
                onMessageManager: onMessageManager,
                onSubmitFollowUp: onSubmitFollowUp,
                onCancelRequest: onCancelRequest,
                onRequestAgain: onRequestAgain,
              );
            },
          );
        },
      ),
    );
  }
}

class _ResidentRequestTile extends StatelessWidget {
  const _ResidentRequestTile({
    required this.request,
    required this.onMessageManager,
    required this.onSubmitFollowUp,
    required this.onCancelRequest,
    required this.onRequestAgain,
  });

  final MaintenanceRequestRecord request;
  final Future<void> Function() onMessageManager;
  final Future<void> Function(MaintenanceRequestRecord request)
  onSubmitFollowUp;
  final Future<void> Function(MaintenanceRequestRecord request) onCancelRequest;
  final Future<void> Function(MaintenanceRequestRecord request) onRequestAgain;

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
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _actionsForStatus(request.status)
                .map(
                  (action) => OutlinedButton.icon(
                    onPressed: action.onPressed,
                    icon: Icon(action.icon, size: 16),
                    label: Text(
                      action.label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: action.color,
                      side: BorderSide(
                        color: action.color.withValues(alpha: 0.4),
                      ),
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  List<_ResidentCardAction> _actionsForStatus(String status) {
    final normalized = status.trim().toLowerCase();
    final hasManagerNote = request.managerNotes.trim().isNotEmpty;

    final message = _ResidentCardAction(
      label: 'Message Manager',
      icon: Icons.chat_bubble_outline_rounded,
      color: const Color(0xFF1A73C8),
      onPressed: onMessageManager,
    );
    final followUp = _ResidentCardAction(
      label: 'Submit Follow-up',
      icon: Icons.reply_rounded,
      color: const Color(0xFF455A6B),
      onPressed: () => onSubmitFollowUp(request),
    );
    final cancel = _ResidentCardAction(
      label: 'Cancel Request',
      icon: Icons.close_rounded,
      color: const Color(0xFF9F3A3A),
      onPressed: () => onCancelRequest(request),
    );
    final again = _ResidentCardAction(
      label: 'Request Again',
      icon: Icons.refresh_rounded,
      color: const Color(0xFF1F8E3D),
      onPressed: () => onRequestAgain(request),
    );

    if (normalized == 'pending') {
      return hasManagerNote ? [message, followUp, cancel] : [message, cancel];
    }
    if (normalized == 'in_progress') {
      return hasManagerNote ? [message, followUp, cancel] : [message, cancel];
    }
    if (normalized == 'resolved') {
      return hasManagerNote ? [again, followUp, message] : [again, message];
    }
    if (normalized == 'cancelled') return [again, message];
    return [message];
  }

  String _statusLabel(String status) {
    final normalized = status.trim().toLowerCase();
    if (normalized == 'in_progress') return 'In Progress';
    if (normalized.isEmpty) return 'Pending';
    return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
  }
}

class _ResidentCardAction {
  const _ResidentCardAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Future<void> Function() onPressed;
}

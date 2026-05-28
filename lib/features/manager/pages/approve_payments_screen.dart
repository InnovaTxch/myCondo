import 'package:flutter/material.dart';
import 'package:mycondo/theme/app_theme.dart';
import 'package:mycondo/data/models/payment_item.dart';
import 'package:mycondo/data/repositories/manager/payment_approval_repository.dart';
import 'package:mycondo/features/manager/widgets/payment_card.dart';
import 'package:mycondo/features/shared/widgets/page_header.dart';
import 'package:mycondo/utils/app_snackbar.dart';
import 'package:mycondo/features/shared/widgets/app_states.dart';

class ApprovePaymentsScreen extends StatefulWidget {
  const ApprovePaymentsScreen({super.key});

  @override
  State<ApprovePaymentsScreen> createState() => _ApprovePaymentsScreenState();
}

class _ApprovePaymentsScreenState extends State<ApprovePaymentsScreen> {
  final PaymentApprovalRepository _repository = PaymentApprovalRepository();
  PaymentStatus selectedTab = PaymentStatus.pending;
  late Map<PaymentStatus, Future<List<PaymentItem>>> _paymentsByStatus;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: selectedTab.index);
    _paymentsByStatus = {
      for (final status in PaymentStatus.values)
        status: _repository.getPayments(status),
    };
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    final future = _repository.getPayments(selectedTab);
    setState(() {
      _paymentsByStatus[selectedTab] = future;
    });
    await future;
  }

  Future<void> _refreshAllPayments() async {
    final updated = {
      for (final status in PaymentStatus.values)
        status: _repository.getPayments(status),
    };
    setState(() {
      _paymentsByStatus = updated;
    });
    await Future.wait(updated.values);
  }

  void _setSelectedTab(PaymentStatus status) {
    if (selectedTab == status) return;
    setState(() {
      selectedTab = status;
    });
    _pageController.animateToPage(
      status.index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlueBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppPageHeader(title: 'Approve Payments'),
              const SizedBox(height: 12),
              _buildTabs(),
              const SizedBox(height: 12),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    final status = PaymentStatus.values[index];
                    if (selectedTab == status) return;
                    setState(() {
                      selectedTab = status;
                    });
                  },
                  children: PaymentStatus.values
                      .map((status) => _buildPaymentsTab(status))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentsTab(PaymentStatus status) {
    return RefreshIndicator(
      onRefresh: () async {
        final future = _repository.getPayments(status);
        setState(() {
          _paymentsByStatus[status] = future;
        });
        await future;
      },
      child: FutureBuilder<List<PaymentItem>>(
        future: _paymentsByStatus[status],
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [SizedBox(height: 120), AppLoadingState()],
            );
          }

          if (snapshot.hasError) {
            debugPrint(
              '[ApprovePaymentsScreen.loadPayments] ${snapshot.error}\n${snapshot.stackTrace ?? ''}',
            );
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                AppErrorState(
                  message: 'Unable to load payments. Try again.',
                  onRetry: _loadPayments,
                ),
              ],
            );
          }

          final payments = snapshot.data ?? const <PaymentItem>[];
          if (payments.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                AppEmptyState(
                  icon: Icons.payments_outlined,
                  title: 'No payments found',
                  message:
                      'Payments will appear here when residents submit them.',
                  card: false,
                ),
              ],
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 20),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return PaymentCard(
                payment: payment,
                onApprove: () => _approve(payment),
                onReject: () => _reject(payment),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.softGray),
      ),
      child: Row(
        children: [
          Expanded(child: _tabItem('Pending', PaymentStatus.pending)),
          Expanded(child: _tabItem('Approved', PaymentStatus.approved)),
          Expanded(child: _tabItem('Rejected', PaymentStatus.rejected)),
        ],
      ),
    );
  }

  Widget _tabItem(String label, PaymentStatus status) {
    final isSelected = selectedTab == status;

    return GestureDetector(
      onTap: () => _setSelectedTab(status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.secondaryText,
          ),
        ),
      ),
    );
  }

  Future<void> _approve(PaymentItem payment) async {
    final confirmed = await _confirmAction(
      title: 'Approve Payment',
      message:
          'Approve this payment from ${payment.residentName}? This will apply it to the bill balance.',
      actionLabel: 'Approve',
    );
    if (!confirmed) return;

    try {
      await _repository.approvePayment(payment);
      await _refreshAllPayments();
    } catch (e, st) {
      if (!mounted) return;
      context.showAppError(
        e,
        stackTrace: st,
        fallbackMessage: 'Could not approve the payment.',
        debugLabel: 'ApprovePaymentsScreen.approve',
      );
    }
  }

  Future<void> _reject(PaymentItem payment) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => const _RejectPaymentDialog(),
    );
    if (reason == null) return;

    final confirmed = await _confirmAction(
      title: 'Deny Payment',
      message:
          'Deny this payment from ${payment.residentName}? The reason will be shown to the resident.',
      actionLabel: 'Deny',
      isDestructive: true,
    );
    if (!confirmed) return;

    try {
      await _repository.rejectPayment(payment: payment, reason: reason);
      await _refreshAllPayments();
    } catch (e, st) {
      if (!mounted) return;
      context.showAppError(
        e,
        stackTrace: st,
        fallbackMessage: 'Could not deny the payment.',
        debugLabel: 'ApprovePaymentsScreen.reject',
      );
    }
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String actionLabel,
    bool isDestructive = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? const Color(0xFFB3261E) : null,
              foregroundColor: isDestructive ? Colors.white : null,
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );

    return confirmed == true;
  }
}

class _RejectPaymentDialog extends StatefulWidget {
  const _RejectPaymentDialog();

  @override
  State<_RejectPaymentDialog> createState() => _RejectPaymentDialogState();
}

class _RejectPaymentDialogState extends State<_RejectPaymentDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Deny Payment'),
      content: TextField(
        controller: _controller,
        minLines: 3,
        maxLines: 5,
        decoration: InputDecoration(
          labelText: 'Reason',
          errorText: _error,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final reason = _controller.text.trim();
            if (reason.isEmpty) {
              setState(() => _error = 'Reason is required.');
              return;
            }
            Navigator.pop(context, reason);
          },
          child: const Text('Deny'),
        ),
      ],
    );
  }
}

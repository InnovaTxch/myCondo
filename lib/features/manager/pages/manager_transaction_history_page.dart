import 'package:flutter/material.dart';
import 'package:mycondo/theme/app_theme.dart';
import 'package:mycondo/data/models/payment_item.dart';
import 'package:mycondo/data/repositories/manager/payment_approval_repository.dart';
import 'package:mycondo/features/manager/widgets/payment_card.dart';
import 'package:mycondo/features/shared/widgets/app_states.dart';
import 'package:mycondo/features/manager/widgets/manager_payment_history_filters.dart';

class ManagerTransactionHistoryPage extends StatefulWidget {
  const ManagerTransactionHistoryPage({super.key});

  @override
  State<ManagerTransactionHistoryPage> createState() =>
      _ManagerTransactionHistoryPageState();
}

class _ManagerTransactionHistoryPageState
    extends State<ManagerTransactionHistoryPage> {
  final PaymentApprovalRepository _repository = PaymentApprovalRepository();
  late Future<List<PaymentItem>> _paymentsFuture;

  final _searchController = TextEditingController();
  PaymentStatus? _statusFilter;
  PaymentHistoryMonthFilter _monthFilter = PaymentHistoryMonthFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _paymentsFuture = _repository.getProcessedPayments();
  }

  void _clearFilters() {
    setState(() {
      _statusFilter = null;
      _monthFilter = PaymentHistoryMonthFilter.all;
    });
  }

  Future<void> _refresh() async {
    final future = _repository.getProcessedPayments();
    setState(() {
      _paymentsFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlueBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Payment History',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Approved and denied payments',
                style: TextStyle(color: Color(0xFF777777)),
              ),
              const SizedBox(height: 12),
              ManagerPaymentHistoryFilters(
                searchController: _searchController,
                onSearchChanged: (_) => setState(() {}),
                statusFilter: _statusFilter,
                onStatusChanged: (value) =>
                    setState(() => _statusFilter = value),
                monthFilter: _monthFilter,
                onMonthChanged: (value) => setState(() => _monthFilter = value),
                onClearFilters: _clearFilters,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<PaymentItem>>(
                  future: _paymentsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const AppLoadingState();
                    }

                    if (snapshot.hasError) {
                      debugPrint(
                        '[ManagerTransactionHistoryPage.loadTransactions] ${snapshot.error}\n${snapshot.stackTrace ?? ''}',
                      );
                      return AppErrorState(
                        message:
                            'Unable to load transactions. Please try again.',
                        onRetry: _refresh,
                      );
                    }

                    final payments = snapshot.data ?? const <PaymentItem>[];
                    final filteredPayments = _applyFilters(payments);
                    if (payments.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            AppEmptyState(
                              title: 'No payments yet',
                              message: 'No processed payments yet.',
                              icon: Icons.receipt_long_outlined,
                              card: false,
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: filteredPayments.length,
                        itemBuilder: (context, index) {
                          return PaymentCard(payment: filteredPayments[index]);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PaymentItem> _applyFilters(List<PaymentItem> payments) {
    final query = _searchController.text.trim().toLowerCase();

    return payments.where((payment) {
      if (_statusFilter != null && payment.status != _statusFilter) {
        return false;
      }
      if (!_matchesMonthFilter(payment.date)) return false;

      if (query.isNotEmpty) {
        final amount = payment.amount / 100;
        final amountText = amount.toStringAsFixed(2);

        final matchesSearch =
            payment.residentName.toLowerCase().contains(query) ||
            payment.room.toLowerCase().contains(query) ||
            payment.billType.toLowerCase().contains(query) ||
            amountText.contains(query) ||
            'php $amountText'.contains(query);

        if (!matchesSearch) return false;
      }

      return true;
    }).toList();
  }

  bool _matchesMonthFilter(String value) {
    if (_monthFilter == PaymentHistoryMonthFilter.all) return true;

    final paymentDate = DateTime.tryParse(value)?.toLocal();
    if (paymentDate == null) return false;

    final now = DateTime.now();

    final subtractMonths = _monthFilter == PaymentHistoryMonthFilter.thisMonth
        ? 0
        : 1;
    final targetMonth = DateTime(now.year, now.month - subtractMonths);

    return paymentDate.year == targetMonth.year &&
        paymentDate.month == targetMonth.month;
  }
}

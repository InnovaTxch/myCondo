import 'package:flutter/material.dart';
import 'package:mycondo/theme/app_theme.dart';
import 'package:mycondo/data/models/payment_item.dart';
import 'package:mycondo/data/repositories/manager/payment_approval_repository.dart';
import 'package:mycondo/features/manager/widgets/payment_card.dart';
import 'package:mycondo/features/shared/widgets/app_states.dart';
import 'package:mycondo/features/manager/widgets/payment_history_filters.dart';

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
  PaymentHistoryDateFilter _dateFilter = PaymentHistoryDateFilter.all;
  DateTimeRange? _customDateRange;

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
      _dateFilter = PaymentHistoryDateFilter.all;
      _customDateRange = null;
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
                onStatusChanged: (value) => setState(() => _statusFilter = value),
                dateFilter: _dateFilter,
                customDateRange: _customDateRange,
                onDateChanged: (value) => setState(() => _dateFilter = value),
                onCustomDateRangeChanged: (value) => setState(() => _customDateRange = value),
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
      if (!_matchesDateFilter(payment.date)) return false;

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

  bool _matchesDateFilter(String value) {
    if (_dateFilter == PaymentHistoryDateFilter.all) return true;

    final paymentDate = DateTime.tryParse(value)?.toLocal();
    if (paymentDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    late final DateTime start;
    late final DateTime endExclusive;

    switch (_dateFilter) {
      case PaymentHistoryDateFilter.today:
        start = today;
        endExclusive = today.add(const Duration(days: 1));
        break;
      case PaymentHistoryDateFilter.yesterday:
        start = today.subtract(const Duration(days: 1));
        endExclusive = today;
        break;
      case PaymentHistoryDateFilter.threeDaysAgo:
        start = today.subtract(const Duration(days: 3));
        endExclusive = start.add(const Duration(days: 1));
        break;
      case PaymentHistoryDateFilter.thisWeek:
        start = today.subtract(Duration(days: today.weekday - 1));
        endExclusive = today.add(const Duration(days: 1));
        break;
      case PaymentHistoryDateFilter.thisMonth:
        start = DateTime(today.year, today.month, 1);
        endExclusive = today.add(const Duration(days: 1));
        break;
      case PaymentHistoryDateFilter.customRange:
        final range = _customDateRange;
        if (range == null) return true;
        start = DateTime(range.start.year, range.start.month, range.start.day);
        endExclusive = DateTime(
          range.end.year,
          range.end.month,
          range.end.day + 1,
        );
        break;
      case PaymentHistoryDateFilter.all:
        return true;
    }
    return !paymentDate.isBefore(start) && paymentDate.isBefore(endExclusive);
  }
}

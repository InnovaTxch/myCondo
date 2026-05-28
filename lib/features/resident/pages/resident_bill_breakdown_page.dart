import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mycondo/data/models/manager/unit_monthly_models.dart';
import 'package:mycondo/data/models/manager/resident_bill_group.dart';
import 'package:mycondo/data/models/shared/bill.dart';
import 'package:mycondo/data/repositories/manager/unit_billing_repository.dart';
import 'package:mycondo/data/repositories/resident/resident_service.dart';
import 'package:mycondo/features/shared/widgets/app_page.dart';
import 'package:mycondo/features/shared/widgets/app_states.dart';
import 'package:mycondo/features/shared/widgets/page_header.dart';
import 'package:mycondo/theme/app_theme.dart';

class ResidentBillBreakdownPage extends StatefulWidget {
  const ResidentBillBreakdownPage({super.key});

  @override
  State<ResidentBillBreakdownPage> createState() =>
      _ResidentBillBreakdownPageState();
}

class _ResidentBillBreakdownPageState extends State<ResidentBillBreakdownPage> {
  static const int _basePageIndex = 1200;

  final ResidentService _service = ResidentService();
  final UnitBillingRepository _unitBillingRepository =
      UnitBillingRepository.instance;
  late Future<List<ResidentBillGroup>> _billsFuture;
  final Map<String, Future<UnitMonthlyLedger>> _unitLedgerFutureByMonth = {};
  late final DateTime _baseMonth;
  late final PageController _monthPageController;
  DateTime _selectedMonth = _toMonth(DateTime.now());

  @override
  void initState() {
    super.initState();
    _baseMonth = _toMonth(DateTime.now());
    _selectedMonth = _baseMonth;
    _monthPageController = PageController(
      initialPage: _basePageIndex,
      viewportFraction: 0.92,
    );
    _billsFuture = _service.fetchBillsForCurrentResident();
  }

  @override
  void dispose() {
    _monthPageController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final future = _service.fetchBillsForCurrentResident();
    setState(() {
      _billsFuture = future;
      _unitLedgerFutureByMonth.clear();
    });
    await future;
    try {
      await _unitLedgerForMonth(_selectedMonth);
    } catch (_) {
      // Keep resident bill refresh resilient even if unit ledger fails to load.
    }
  }

  Future<void> _openMonthPicker() async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MonthYearPickerSheet(
        initialMonth: _selectedMonth,
        yearOptions: _buildYearOptions(),
      ),
    );

    if (!mounted || picked == null) return;
    final selected = _toMonth(picked);
    final page = _pageIndexForMonth(selected);
    await _monthPageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
    if (!mounted) return;
    setState(() => _selectedMonth = selected);
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'PHP ', decimalDigits: 2);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = _horizontalPaddingFor(screenWidth);
    final headerTopPadding = screenWidth < 380 ? 8.0 : 12.0;

    return AppPageScaffold(
      appBar: appPageAppBar(context: context, title: 'Bill Breakdown'),
      body: FutureBuilder<List<ResidentBillGroup>>(
        future: _billsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState();
          }

          if (snapshot.hasError) {
            return AppScrollableCentered(
              child: AppErrorState(
                message: 'Unable to load bill breakdown.',
                onRetry: _refresh,
              ),
            );
          }

          final allBills = snapshot.data ?? const <ResidentBillGroup>[];
          final statusColors = context.appStatusColors;

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  headerTopPadding,
                  horizontalPadding,
                  8,
                ),
                child: Center(
                  child: Material(
                    color: AppColors.pureWhite,
                    borderRadius: BorderRadius.circular(999),
                    child: InkWell(
                      onTap: _openMonthPicker,
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth < 380 ? 12 : 14,
                          vertical: screenWidth < 380 ? 8 : 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.softGray),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_month_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('MMMM yyyy').format(_selectedMonth),
                              style: TextStyle(
                                fontSize: screenWidth < 380 ? 16 : 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.expand_more_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat('MMM yyyy').format(
                          DateTime(
                            _selectedMonth.year,
                            _selectedMonth.month - 1,
                            1,
                          ),
                        ),
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.swipe_rounded,
                      size: 14,
                      color: AppColors.secondaryText,
                    ),
                    Expanded(
                      child: Text(
                        DateFormat('MMM yyyy').format(
                          DateTime(
                            _selectedMonth.year,
                            _selectedMonth.month + 1,
                            1,
                          ),
                        ),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _monthPageController,
                  padEnds: true,
                  onPageChanged: (pageIndex) {
                    setState(() {
                      _selectedMonth = _monthForPageIndex(pageIndex);
                    });
                  },
                  itemBuilder: (context, pageIndex) {
                    final month = _monthForPageIndex(pageIndex);
                    final monthBills =
                        allBills
                            .where(
                              (bill) =>
                                  _isSameMonth(_toLocalIssuedAt(bill), month),
                            )
                            .toList()
                          ..sort((a, b) => b.issuedAt.compareTo(a.issuedAt));

                    return FutureBuilder<UnitMonthlyLedger>(
                      future: _unitLedgerForMonth(month),
                      builder: (context, unitSnapshot) {
                        final entries =
                            [
                              ...monthBills.map(
                                _BillBreakdownEntry.fromResidentBill,
                              ),
                              if (unitSnapshot.hasData &&
                                  unitSnapshot.data!.hasAssignedBill)
                                _BillBreakdownEntry.fromUnitLedger(
                                  unitSnapshot.data!,
                                ),
                            ]..sort((a, b) {
                              if (a.isSharedUnitBill != b.isSharedUnitBill) {
                                return a.isSharedUnitBill ? -1 : 1;
                              }
                              return b.issuedAt.compareTo(a.issuedAt);
                            });

                        final totalIssued = entries.fold<int>(
                          0,
                          (total, bill) => total + bill.totalAmount,
                        );
                        final totalOutstanding = entries.fold<int>(
                          0,
                          (total, bill) => total + bill.outstandingAmount,
                        );
                        final totalOverdue = entries.fold<int>(
                          0,
                          (total, bill) =>
                              total +
                              (bill.status == 'overdue'
                                  ? bill.outstandingAmount
                                  : 0),
                        );

                        return Padding(
                          padding: EdgeInsets.fromLTRB(
                            screenWidth < 380 ? 4 : 6,
                            0,
                            screenWidth < 380 ? 4 : 6,
                            0,
                          ),
                          child: RefreshIndicator(
                            onRefresh: _refresh,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                4,
                                8,
                                4,
                                screenWidth < 380 ? 18 : 24,
                              ),
                              children: [
                                if (entries.isNotEmpty) ...[
                                  _MonthSummaryPanel(
                                    screenWidth: screenWidth,
                                    billCount: entries.length,
                                    totalIssued: currency.format(
                                      totalIssued / 100,
                                    ),
                                    totalOverdue: currency.format(
                                      totalOverdue / 100,
                                    ),
                                    totalOutstanding: currency.format(
                                      totalOutstanding / 100,
                                    ),
                                    overdueColor: totalOverdue > 0
                                        ? statusColors.destructive
                                        : statusColors.success,
                                    outstandingColor: totalOutstanding > 0
                                        ? statusColors.warningStrong
                                        : statusColors.success,
                                  ),
                                  const SizedBox(height: 14),
                                ],
                                if (entries.isEmpty &&
                                    unitSnapshot.connectionState ==
                                        ConnectionState.waiting)
                                  const AppLoadingState()
                                else if (entries.isEmpty)
                                  const AppEmptyState(
                                    icon: Icons.receipt_long_outlined,
                                    title: 'No bills issued this month',
                                    message:
                                        'Choose a different month to view issued bills.',
                                  )
                                else
                                  ...entries.map(
                                    (entry) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: _BreakdownCard(entry: entry),
                                    ),
                                  ),
                                if (unitSnapshot.hasError)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Text(
                                      'Unable to load unit bill details for this month.',
                                      style: TextStyle(
                                        color: AppColors.secondaryText,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  DateTime _monthForPageIndex(int pageIndex) {
    final delta = pageIndex - _basePageIndex;
    return DateTime(_baseMonth.year, _baseMonth.month + delta, 1);
  }

  int _pageIndexForMonth(DateTime month) {
    final normalized = _toMonth(month);
    final monthDelta =
        (normalized.year - _baseMonth.year) * 12 +
        (normalized.month - _baseMonth.month);
    return _basePageIndex + monthDelta;
  }

  List<int> _buildYearOptions() {
    const startYear = 1970;
    const endYear = 2100;
    return List<int>.generate(endYear - startYear + 1, (i) => startYear + i);
  }

  double _horizontalPaddingFor(double width) {
    if (width >= 900) return 28;
    if (width >= 600) return 24;
    if (width < 380) return 12;
    return 20;
  }

  Future<UnitMonthlyLedger> _unitLedgerForMonth(DateTime month) {
    final key = _monthKey(month);
    return _unitLedgerFutureByMonth.putIfAbsent(
      key,
      () =>
          _unitBillingRepository.getUnitMonthlyLedgerForResident(month: month),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.entry});

  final _BillBreakdownEntry entry;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'PHP ', decimalDigits: 2);
    final issuedLabel = DateFormat(
      'MMM d, yyyy',
    ).format(entry.issuedAt.toLocal());
    final dueLabel = DateFormat('MMM d, yyyy').format(entry.dueDate.toLocal());
    final paidOnLabel = entry.fullyPaidAt == null
        ? null
        : DateFormat('MMM d, yyyy').format(entry.fullyPaidAt!.toLocal());
    final statusColors = context.appStatusColors;
    final statusColor = _statusColor(
      status: entry.status,
      statusColors: statusColors,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.softGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  entry.billType,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _formatStatus(entry.status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Issued $issuedLabel',
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Due $dueLabel',
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (paidOnLabel != null) ...[
            const SizedBox(height: 2),
            Text(
              'Paid on $paidOnLabel',
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          ...entry.bills.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(currency.format(item.amount / 100)),
                ],
              ),
            ),
          ),
          const Divider(height: 20),
          _SummaryRow(
            label: 'Total Issued',
            value: currency.format(entry.totalAmount / 100),
            valueColor: AppColors.darkText,
            strong: true,
          ),
          const SizedBox(height: 6),
          _SummaryRow(
            label: 'Outstanding',
            value: currency.format(entry.outstandingAmount / 100),
            valueColor: entry.outstandingAmount > 0
                ? statusColors.warningStrong
                : statusColors.success,
            strong: true,
          ),
          if (entry.status == 'paid' && entry.fullyPaidAt != null) ...[
            const SizedBox(height: 8),
            Text(
              '*Fully paid on ${DateFormat('MMM d, yyyy').format(entry.fullyPaidAt!.toLocal())}',
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BillBreakdownEntry {
  const _BillBreakdownEntry({
    required this.billType,
    required this.issuedAt,
    required this.dueDate,
    required this.status,
    required this.bills,
    required this.totalAmount,
    required this.outstandingAmount,
    required this.isSharedUnitBill,
    required this.fullyPaidAt,
  });

  final String billType;
  final DateTime issuedAt;
  final DateTime dueDate;
  final String status;
  final List<Bill> bills;
  final int totalAmount;
  final int outstandingAmount;
  final bool isSharedUnitBill;
  final DateTime? fullyPaidAt;

  factory _BillBreakdownEntry.fromResidentBill(ResidentBillGroup bill) {
    DateTime? fullyPaidAt;
    for (final payment in bill.payments) {
      if (payment.status != 'completed') continue;
      final paidAt = payment.createdAt;
      if (fullyPaidAt == null || paidAt.isAfter(fullyPaidAt)) {
        fullyPaidAt = paidAt;
      }
    }

    return _BillBreakdownEntry(
      billType: bill.billType,
      issuedAt: bill.issuedAt,
      dueDate: bill.dueDate,
      status: bill.status,
      bills: bill.bills,
      totalAmount: bill.totalAmount,
      outstandingAmount: bill.outstandingAmount,
      isSharedUnitBill: false,
      fullyPaidAt: fullyPaidAt,
    );
  }

  factory _BillBreakdownEntry.fromUnitLedger(UnitMonthlyLedger ledger) {
    final chargeBreakdown = ledger.charges
        .map((charge) => Bill(name: charge.name, amount: charge.amount))
        .toList();
    DateTime? fullyPaidAt;
    for (final payment in ledger.payments) {
      final paidAt = payment.paidAt;
      if (fullyPaidAt == null || paidAt.isAfter(fullyPaidAt)) {
        fullyPaidAt = paidAt;
      }
    }

    return _BillBreakdownEntry(
      billType: 'Unit Bill (Shared)',
      issuedAt: DateTime(ledger.month.year, ledger.month.month, 1),
      dueDate: ledger.dueDate,
      status: ledger.status,
      bills: chargeBreakdown.isEmpty
          ? [Bill(name: 'Shared Unit Bill', amount: ledger.totalAmount)]
          : chargeBreakdown,
      totalAmount: ledger.totalAmount,
      outstandingAmount: ledger.remainingAmount,
      isSharedUnitBill: true,
      fullyPaidAt: fullyPaidAt,
    );
  }
}

class _MonthSummaryPanel extends StatelessWidget {
  const _MonthSummaryPanel({
    required this.screenWidth,
    required this.billCount,
    required this.totalIssued,
    required this.totalOverdue,
    required this.totalOutstanding,
    required this.overdueColor,
    required this.outstandingColor,
  });

  final double screenWidth;
  final int billCount;
  final String totalIssued;
  final String totalOverdue;
  final String totalOutstanding;
  final Color overdueColor;
  final Color outstandingColor;

  @override
  Widget build(BuildContext context) {
    final isCompact = screenWidth < 380;
    final isTablet = screenWidth >= 600;

    return Container(
      padding: EdgeInsets.fromLTRB(
        isCompact ? 12 : 16,
        isCompact ? 12 : 16,
        isCompact ? 12 : 16,
        isCompact ? 10 : 14,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.skyBlue.withValues(alpha: 0.42),
            AppColors.softLavender.withValues(alpha: 0.42),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Month Summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: isCompact ? 6 : 8,
            mainAxisSpacing: isCompact ? 6 : 8,
            childAspectRatio: isTablet ? 2.6 : (isCompact ? 1.95 : 2.25),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _SummaryStatChip(
                label: 'Bills Issued',
                value: billCount.toString(),
                valueColor: AppColors.darkText,
              ),
              _SummaryStatChip(
                label: 'Total Bill Amount',
                value: totalIssued,
                valueColor: AppColors.darkText,
              ),
              _SummaryStatChip(
                label: 'Overdue Amount',
                value: totalOverdue,
                valueColor: overdueColor,
              ),
              _SummaryStatChip(
                label: 'Outstanding',
                value: totalOutstanding,
                valueColor: outstandingColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStatChip extends StatelessWidget {
  const _SummaryStatChip({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.pureWhite.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.strong = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.secondaryText,
              fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: strong ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MonthYearPickerSheet extends StatefulWidget {
  const _MonthYearPickerSheet({
    required this.initialMonth,
    required this.yearOptions,
  });

  final DateTime initialMonth;
  final List<int> yearOptions;

  @override
  State<_MonthYearPickerSheet> createState() => _MonthYearPickerSheetState();
}

class _MonthYearPickerSheetState extends State<_MonthYearPickerSheet> {
  late int _month;
  late int _year;

  static final List<int> _months = List<int>.generate(12, (index) => index + 1);

  @override
  void initState() {
    super.initState();
    _month = widget.initialMonth.month;
    _year = widget.initialMonth.year;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: const BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose Month',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _month,
                    decoration: const InputDecoration(labelText: 'Month'),
                    items: _months
                        .map(
                          (value) => DropdownMenuItem<int>(
                            value: value,
                            child: Text(
                              DateFormat('MMMM').format(DateTime(2000, value)),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _month = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: widget.yearOptions.contains(_year)
                        ? _year
                        : widget.yearOptions.last,
                    decoration: const InputDecoration(labelText: 'Year'),
                    items: widget.yearOptions
                        .map(
                          (value) => DropdownMenuItem<int>(
                            value: value,
                            child: Text(value.toString()),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _year = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, DateTime(_year, _month, 1));
                    },
                    child: const Text('Go'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

DateTime _toLocalIssuedAt(ResidentBillGroup bill) {
  return bill.issuedAt.toLocal();
}

DateTime _toMonth(DateTime date) {
  final local = date.toLocal();
  return DateTime(local.year, local.month, 1);
}

bool _isSameMonth(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month;
}

String _monthKey(DateTime month) =>
    '${month.year}-${month.month.toString().padLeft(2, '0')}';

String _formatStatus(String status) {
  final words = status
      .split('_')
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}');
  return words.join(' ');
}

Color _statusColor({
  required String status,
  required AppStatusColors statusColors,
}) {
  switch (status) {
    case 'paid':
      return statusColors.success;
    case 'partial':
      return AppColors.primaryBlue;
    case 'overdue':
      return statusColors.destructive;
    default:
      return statusColors.warningStrong;
  }
}

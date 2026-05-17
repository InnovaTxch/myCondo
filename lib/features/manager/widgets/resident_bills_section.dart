import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mycondo/data/models/manager/resident_bill_group.dart';
import 'package:mycondo/data/repositories/manager/resident_bill_repository.dart';
import 'package:mycondo/features/shared/widgets/app_states.dart';
import 'package:mycondo/theme/app_theme.dart';

class ResidentBillsSection extends StatefulWidget {
  const ResidentBillsSection({
    super.key,
    required this.residentId,
    required this.onViewBreakdown,
  });

  final String residentId;
  final VoidCallback onViewBreakdown;

  @override
  State<ResidentBillsSection> createState() => _ResidentBillsSectionState();
}

class _ResidentBillsSectionState extends State<ResidentBillsSection> {
  late Future<List<ResidentBillGroup>> _billsFuture;

  final ResidentBillRepository _repository = ResidentBillRepository.instance;

  @override
  void initState() {
    super.initState();
    _billsFuture = _repository.getBillsForResident(widget.residentId);
  }

  Future<void> _refresh() async {
    final future = _repository.getBillsForResident(widget.residentId);
    setState(() {
      _billsFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'PHP ', decimalDigits: 2);
    return FutureBuilder<List<ResidentBillGroup>>(
      future: _billsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: AppLoadingState(),
          );
        }

        if (snapshot.hasError) {
          return AppErrorState(
            message: 'Unable to load bills. Try again.',
            details: '${snapshot.error}',
            onRetry: _refresh,
          );
        }

        final bills = snapshot.data ?? const <ResidentBillGroup>[];
        final currentMonth = DateTime.now();
        final monthBills = bills
            .where(
              (bill) => _isSameMonth(bill.issuedAt.toLocal(), currentMonth),
            )
            .toList();
        final openCount = monthBills.where((bill) => !bill.isPaid).length;
        final totalIssued = monthBills.fold<int>(
          0,
          (sum, bill) => sum + bill.totalAmount,
        );
        final totalOutstanding = monthBills.fold<int>(
          0,
          (sum, bill) => sum + bill.outstandingAmount,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Bills',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => _openBillStatusCalendar(bills),
                  tooltip: 'Billing Calendar',
                  icon: const Icon(
                    Icons.calendar_month_outlined,
                    color: AppColors.secondaryText,
                    size: 20,
                  ),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(currentMonth),
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SummaryRow(
              label: 'Issued this month',
              value: currency.format(totalIssued / 100),
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Outstanding',
              value: currency.format(totalOutstanding / 100),
              valueColor: totalOutstanding > 0
                  ? context.appStatusColors.destructive
                  : context.appStatusColors.success,
            ),
            const SizedBox(height: 8),
            _SummaryRow(label: 'Open bills', value: '$openCount'),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onViewBreakdown,
                icon: const Icon(Icons.swipe_rounded),
                label: const Text('View Full Breakdown'),
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  Future<void> _openBillStatusCalendar(List<ResidentBillGroup> bills) async {
    final currentDate = DateTime.now();
    var selectedYear = currentDate.year;
    var minYear = currentDate.year;
    var maxYear = currentDate.year;

    for (final bill in bills) {
      final year = bill.issuedAt.toLocal().year;
      if (year < minYear) minYear = year;
      if (year > maxYear) maxYear = year;
    }

    minYear -= 1;
    maxYear += 1;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Billing Calendar'),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: selectedYear > minYear
                              ? () {
                                  setDialogState(() => selectedYear--);
                                }
                              : null,
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        Expanded(
                          child: Text(
                            '$selectedYear',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: selectedYear < maxYear
                              ? () {
                                  setDialogState(() => selectedYear++);
                                }
                              : null,
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 12,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 2.2,
                          ),
                      itemBuilder: (context, index) {
                        final month = index + 1;
                        final monthDate = DateTime(selectedYear, month, 1);
                        final monthBills = bills
                            .where(
                              (bill) => _isSameMonth(
                                bill.issuedAt.toLocal(),
                                monthDate,
                              ),
                            )
                            .toList();
                        final status = _monthStatus(monthBills);
                        final isCurrentMonth = _isSameMonth(
                          monthDate,
                          currentDate,
                        );
                        final statusColor = _statusColorForMonth(
                          context,
                          status,
                        );

                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.pureWhite,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isCurrentMonth
                                  ? AppColors.primaryBlue
                                  : AppColors.softGray,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  DateFormat('MMM').format(monthDate),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              if (status != _MonthBillingStatus.none)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        _LegendDot(
                          label: 'Overdue',
                          color: context.appStatusColors.destructive,
                        ),
                        _LegendDot(
                          label: 'Pending',
                          color: AppColors.warningGold,
                        ),
                        _LegendDot(
                          label: 'Paid',
                          color: context.appStatusColors.success,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  _MonthBillingStatus _monthStatus(List<ResidentBillGroup> monthBills) {
    if (monthBills.isEmpty) return _MonthBillingStatus.none;
    final hasOverdue = monthBills.any((bill) => bill.status == 'overdue');
    if (hasOverdue) return _MonthBillingStatus.overdue;
    final allPaid = monthBills.every((bill) => bill.isPaid);
    if (allPaid) return _MonthBillingStatus.paid;
    return _MonthBillingStatus.pending;
  }

  Color _statusColorForMonth(BuildContext context, _MonthBillingStatus status) {
    switch (status) {
      case _MonthBillingStatus.overdue:
        return context.appStatusColors.destructive;
      case _MonthBillingStatus.pending:
        return AppColors.warningGold;
      case _MonthBillingStatus.paid:
        return context.appStatusColors.success;
      case _MonthBillingStatus.none:
        return Colors.transparent;
    }
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.darkText,
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
        ),
      ],
    );
  }
}

enum _MonthBillingStatus { none, overdue, pending, paid }

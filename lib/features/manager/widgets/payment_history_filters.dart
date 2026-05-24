import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mycondo/data/models/payment_item.dart';
import 'package:mycondo/theme/app_theme.dart';

enum PaymentHistoryDateFilter {
  all,
  today,
  yesterday,
  threeDaysAgo,
  thisWeek,
  thisMonth,
  customRange,
}

const _dateFilterOptions = [
  PaymentHistoryDateFilter.all,
  PaymentHistoryDateFilter.today,
  PaymentHistoryDateFilter.yesterday,
  PaymentHistoryDateFilter.threeDaysAgo,
  PaymentHistoryDateFilter.thisWeek,
  PaymentHistoryDateFilter.thisMonth,
  PaymentHistoryDateFilter.customRange,
];

class ManagerPaymentHistoryFilters extends StatelessWidget {
  const ManagerPaymentHistoryFilters({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.statusFilter,
    required this.onStatusChanged,
    required this.dateFilter,
    required this.customDateRange,
    required this.onDateChanged,
    required this.onCustomDateRangeChanged,
    required this.onClearFilters,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final PaymentStatus? statusFilter;
  final ValueChanged<PaymentStatus?> onStatusChanged;
  final PaymentHistoryDateFilter dateFilter;
  final DateTimeRange? customDateRange;
  final ValueChanged<PaymentHistoryDateFilter> onDateChanged;
  final ValueChanged<DateTimeRange?> onCustomDateRangeChanged;
  final VoidCallback onClearFilters;

  bool get _hasActiveFilters =>
      statusFilter != null || dateFilter != PaymentHistoryDateFilter.all;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search resident, unit, bill type, or amount',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: IconButton(
              tooltip: 'Filter payments',
              onPressed: () => _openFilterSheet(context),
              icon: const Icon(Icons.tune_rounded),
            ),
            filled: true,
            fillColor: AppColors.lightBlueBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(
                color: AppColors.skyBlue,
                width: 1.5,
                ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(
                color: AppColors.primaryBlue,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (_hasActiveFilters) ...[
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (statusFilter != null)...[
                  _activeChip(
                    label: _statusLabel(statusFilter!),
                    onDeleted: () => onStatusChanged(null),
                  ),
                  const SizedBox(width: 8),
                ],
                if (dateFilter != PaymentHistoryDateFilter.all)...[
                  _activeChip(
                    label: _dateLabel(dateFilter, customDateRange),
                    onDeleted: () {
                      onDateChanged(PaymentHistoryDateFilter.all);
                      onCustomDateRangeChanged(null);
                    },
                  ),
                const SizedBox(width: 8),
                ],
                TextButton(
                  onPressed: onClearFilters,
                  child: const Text('Clear all'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _activeChip({
    required String label,
    required VoidCallback onDeleted,
  }) {
    return InputChip(
      label: Text(label),
      onDeleted: onDeleted,
      backgroundColor: AppColors.lightBlueBackground,
      selectedColor: AppColors.skyBlue,
      deleteIconColor: AppColors.secondaryText,
      side: const BorderSide(color: AppColors.primaryBlue),
      labelStyle: const TextStyle(
        color: AppColors.darkText,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _dateChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: _choiceChip(
        label: label,
        selected: selected,
        onSelected: onSelected,
      ),
    );
  }

  void _openFilterSheet(BuildContext context) {
    var tempStatus = statusFilter;
    var tempDate = dateFilter;
    var tempRange = customDateRange;

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.38,
              minChildSize: 0.37,
              maxChildSize: 0.40,
              expand: false,
              builder: (context, scrollController) {
                return SafeArea(
                  top: false,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      12 + MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.pureWhite,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 44,
                              height: 5,
                              decoration: BoxDecoration(
                                color: AppColors.softGray,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Filter payments',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const _FilterLabel('Status'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              _choiceChip(
                                label: 'All',
                                selected: tempStatus == null,
                                onSelected: () =>
                                    setSheetState(() => tempStatus = null),
                              ),
                              _choiceChip(
                                label: 'Approved',
                                selected: tempStatus == PaymentStatus.approved,
                                onSelected: () => setSheetState(
                                  () => tempStatus = PaymentStatus.approved,
                                ),
                              ),
                              _choiceChip(
                                label: 'Denied',
                                selected: tempStatus == PaymentStatus.rejected,
                                onSelected: () => setSheetState(
                                  () => tempStatus = PaymentStatus.rejected,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const _FilterLabel('Date'),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _dateFilterOptions.map((filter) {
                                return _dateChip(
                                  label: _dateLabel(
                                    filter,
                                    filter == PaymentHistoryDateFilter.customRange ? tempRange : null,
                                  ),
                                  selected: tempDate == filter,
                                  onSelected: () async {
                                    if (filter == PaymentHistoryDateFilter.customRange) {
                                      final picked = await showDialog<DateTimeRange>(
                                        context: context,
                                        builder: (context) {
                                          return DateRangePickerDialog(
                                            initialDateRange: tempRange,
                                            firstDate: DateTime(1970, 1, 1),
                                            lastDate: DateTime.now(),
                                            helpText: 'Select date range',
                                            saveText: 'Apply',
                                          );
                                        },
                                      );

                                      if (picked == null) return;

                                      setSheetState(() {
                                        tempDate = PaymentHistoryDateFilter.customRange;
                                        tempRange = picked;
                                      });
                                      return;
                                    }

                                    setSheetState(() {
                                      tempDate = filter;
                                      tempRange = null;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    onStatusChanged(null);
                                    onDateChanged(PaymentHistoryDateFilter.all);
                                    onCustomDateRangeChanged(null);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Clear filters'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    onStatusChanged(tempStatus);
                                    onDateChanged(tempDate);
                                    onCustomDateRangeChanged(tempRange);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Apply'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _choiceChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primaryBlue,
      backgroundColor: AppColors.creamWhite,
      checkmarkColor: AppColors.pureWhite,
      side: BorderSide(
        color: selected ? AppColors.primaryBlue : AppColors.softGray,
      ),
      labelStyle: TextStyle(
        color: selected ? AppColors.pureWhite : AppColors.darkText,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  String _statusLabel(PaymentStatus status) {
    return status == PaymentStatus.approved ? 'Approved' : 'Denied';
  }

  String _dateLabel(PaymentHistoryDateFilter filter, DateTimeRange? customRange,) {
    switch (filter) {
      case PaymentHistoryDateFilter.today:
        return 'Today';
      case PaymentHistoryDateFilter.yesterday:
        return 'Yesterday';
      case PaymentHistoryDateFilter.threeDaysAgo:
        return '3 days ago';
      case PaymentHistoryDateFilter.thisWeek:
        return 'This week';
      case PaymentHistoryDateFilter.thisMonth:
        return 'This month';
      case PaymentHistoryDateFilter.customRange:
        return customRange == null ? 'Select range' : _formatRange(customRange);
      case PaymentHistoryDateFilter.all:
        return 'All dates';
    }
  }
}

String _formatRange(DateTimeRange range) {
  final formatter = DateFormat('MMM d');
  return '${formatter.format(range.start)} - ${formatter.format(range.end)}';
}

class _FilterLabel extends StatelessWidget {
  const _FilterLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        color: AppColors.darkText,
      ),
    );
  }
}

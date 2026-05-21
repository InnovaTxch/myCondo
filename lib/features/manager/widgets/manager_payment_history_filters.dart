import 'package:flutter/material.dart';
import 'package:mycondo/data/models/payment_item.dart';
import 'package:mycondo/theme/app_theme.dart';

enum PaymentHistoryMonthFilter { all, thisMonth, lastMonth }

class ManagerPaymentHistoryFilters extends StatelessWidget {
  const ManagerPaymentHistoryFilters({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.statusFilter,
    required this.onStatusChanged,
    required this.monthFilter,
    required this.onMonthChanged,
    required this.onClearFilters,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final PaymentStatus? statusFilter;
  final ValueChanged<PaymentStatus?> onStatusChanged;
  final PaymentHistoryMonthFilter monthFilter;
  final ValueChanged<PaymentHistoryMonthFilter> onMonthChanged;
  final VoidCallback onClearFilters;

  bool get _hasActiveFilters =>
      statusFilter != null || monthFilter != PaymentHistoryMonthFilter.all;

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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (statusFilter != null)
                _activeChip(
                  label: _statusLabel(statusFilter!),
                  onDeleted: () => onStatusChanged(null),
                ),
              if (monthFilter != PaymentHistoryMonthFilter.all)
                _activeChip(
                  label: _monthLabel(monthFilter),
                  onDeleted: () => onMonthChanged(PaymentHistoryMonthFilter.all),
                ),
              TextButton(
                onPressed: onClearFilters,
                child: const Text('Clear all'),
              ),
            ],
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

  void _openFilterSheet(BuildContext context) {
    var tempStatus = statusFilter;
    var tempMonth = monthFilter;

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
                          const _FilterLabel('Month'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              _choiceChip(
                                label: 'All months',
                                selected:
                                    tempMonth == PaymentHistoryMonthFilter.all,
                                onSelected: () => setSheetState(
                                  () => tempMonth =
                                      PaymentHistoryMonthFilter.all,
                                ),
                              ),
                              _choiceChip(
                                label: 'This month',
                                selected: tempMonth ==
                                    PaymentHistoryMonthFilter.thisMonth,
                                onSelected: () => setSheetState(
                                  () => tempMonth =
                                      PaymentHistoryMonthFilter.thisMonth,
                                ),
                              ),
                              _choiceChip(
                                label: 'Last month',
                                selected: tempMonth ==
                                    PaymentHistoryMonthFilter.lastMonth,
                                onSelected: () => setSheetState(
                                  () => tempMonth =
                                      PaymentHistoryMonthFilter.lastMonth,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    onStatusChanged(null);
                                    onMonthChanged(
                                      PaymentHistoryMonthFilter.all,
                                    );
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
                                    onMonthChanged(tempMonth);
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

  String _monthLabel(PaymentHistoryMonthFilter filter) {
    switch (filter) {
      case PaymentHistoryMonthFilter.thisMonth:
        return 'This month';
      case PaymentHistoryMonthFilter.lastMonth:
        return 'Last month';
      case PaymentHistoryMonthFilter.all:
        return 'All months';
    }
  }
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

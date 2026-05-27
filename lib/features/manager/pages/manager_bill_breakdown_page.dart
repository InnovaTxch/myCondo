import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mycondo/data/models/manager/resident_bill_group.dart';
import 'package:mycondo/data/models/shared/bill.dart';
import 'package:mycondo/data/repositories/manager/resident_bill_repository.dart';
import 'package:mycondo/features/manager/widgets/resident_bill_add_sheet.dart';
import 'package:mycondo/features/manager/widgets/resident_bill_card.dart';
import 'package:mycondo/features/manager/widgets/resident_bill_payment_sheet.dart';
import 'package:mycondo/features/shared/widgets/app_states.dart';
import 'package:mycondo/theme/app_theme.dart';
import 'package:mycondo/utils/app_snackbar.dart';

class ManagerBillBreakdownPage extends StatefulWidget {
  const ManagerBillBreakdownPage({
    super.key,
    required this.residentId,
    required this.residentName,
  });

  final String residentId;
  final String residentName;

  @override
  State<ManagerBillBreakdownPage> createState() =>
      _ManagerBillBreakdownPageState();
}

class _ManagerBillBreakdownPageState extends State<ManagerBillBreakdownPage> {
  static const int _basePageIndex = 1200;

  final ResidentBillRepository _repository = ResidentBillRepository.instance;
  late Future<List<ResidentBillGroup>> _billsFuture;
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
      viewportFraction: 0.9,
    );
    _billsFuture = _repository.getBillsForResident(widget.residentId);
  }

  @override
  void dispose() {
    _monthPageController.dispose();
    super.dispose();
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
    return Scaffold(
      backgroundColor: AppColors.lightBlueBackground,
      appBar: AppBar(
        title: const Text('Bill Breakdown'),
        actions: [
          TextButton.icon(
            onPressed: _openAddBillSheet,
            icon: const Icon(Icons.add),
            label: const Text('Add Bill'),
          ),
        ],
      ),
      body: FutureBuilder<List<ResidentBillGroup>>(
        future: _billsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState();
          }
          if (snapshot.hasError) {
            debugPrint(
              '[ManagerBillBreakdownPage.loadBills] ${snapshot.error}\n${snapshot.stackTrace ?? ''}',
            );
            return AppErrorState(
              message: 'Unable to load bills. Try again.',
              onRetry: _refresh,
            );
          }

          final bills = snapshot.data ?? const <ResidentBillGroup>[];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Text(
                  widget.residentName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _pickMonthAndJump,
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.softGray),
                          color: AppColors.pureWhite,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat('MMMM yyyy').format(_selectedMonth),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.expand_more_rounded,
                              size: 18,
                              color: AppColors.secondaryText,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
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
                  onPageChanged: (pageIndex) {
                    setState(() {
                      _selectedMonth = _monthForPageIndex(pageIndex);
                    });
                  },
                  itemBuilder: (context, pageIndex) {
                    final month = _monthForPageIndex(pageIndex);
                    final monthBills =
                        bills
                            .where(
                              (bill) =>
                                  _isSameMonth(bill.issuedAt.toLocal(), month),
                            )
                            .toList()
                          ..sort((a, b) => b.issuedAt.compareTo(a.issuedAt));

                    final openBills = monthBills
                        .where((bill) => !bill.isPaid)
                        .toList();
                    final paidBills = monthBills
                        .where((bill) => bill.isPaid)
                        .toList();

                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                          children: [
                            if (monthBills.isEmpty)
                              const AppEmptyState(
                                icon: Icons.receipt_long_outlined,
                                title: 'No bills this month',
                                message:
                                    'Swipe to another month to view bills.',
                                card: true,
                              )
                            else ...[
                              if (openBills.isNotEmpty) ...[
                                ...openBills.map(
                                  (bill) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: ResidentBillCard(
                                      bill: bill,
                                      onPayment: () => _openPaymentSheet(bill),
                                      onDelete: () => _confirmDelete(bill),
                                    ),
                                  ),
                                ),
                              ],
                              if (paidBills.isNotEmpty) ...[
                                if (openBills.isNotEmpty)
                                  const SizedBox(height: 10),
                                ...paidBills.map(
                                  (bill) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: ResidentBillCard(
                                      bill: bill,
                                      onPayment: () => _openPaymentSheet(bill),
                                      onDelete: () => _confirmDelete(bill),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
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

  Future<void> _openAddBillSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => ResidentBillAddSheet(
        onSubmit:
            ({
              required String billType,
              required DateTime dueDate,
              required List<Bill> bills,
            }) => _repository.addBill(
              residentId: widget.residentId,
              billType: billType,
              dueDate: dueDate,
              bills: bills,
            ),
      ),
    );
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _openPaymentSheet(ResidentBillGroup bill) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => ResidentBillPaymentSheet(
        bill: bill,
        onSubmit: (amount) => _repository.recordPayment(
          bill: bill,
          residentId: widget.residentId,
          amount: amount,
        ),
      ),
    );
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _confirmDelete(ResidentBillGroup bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bill'),
        content: const Text('This will remove the bill and its payments.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _repository.deleteBill(bill);
      await _refresh();
    } catch (e, st) {
      if (!mounted) return;
      context.showAppError(
        e,
        stackTrace: st,
        fallbackMessage: 'Could not delete the bill.',
        debugLabel: 'ManagerBillBreakdownPage.deleteBill',
      );
    }
  }

  DateTime _monthForPageIndex(int pageIndex) {
    final delta = pageIndex - _basePageIndex;
    return DateTime(_baseMonth.year, _baseMonth.month + delta, 1);
  }

  Future<void> _pickMonthAndJump() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(1970, 1, 1),
      lastDate: DateTime(2100, 12, 31),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (!mounted || pickedDate == null) return;
    final targetMonth = _toMonth(pickedDate);
    final pageIndex = _pageIndexForMonth(targetMonth);
    await _monthPageController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
    if (!mounted) return;
    setState(() => _selectedMonth = targetMonth);
  }

  int _pageIndexForMonth(DateTime month) {
    final normalized = _toMonth(month);
    final monthDelta =
        (normalized.year - _baseMonth.year) * 12 +
        (normalized.month - _baseMonth.month);
    return _basePageIndex + monthDelta;
  }

  static DateTime _toMonth(DateTime date) => DateTime(date.year, date.month, 1);

  static bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }
}

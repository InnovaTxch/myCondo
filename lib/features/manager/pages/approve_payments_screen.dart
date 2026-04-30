import 'package:flutter/material.dart';
import 'package:mycondo/data/models/payment_item.dart';
import 'package:mycondo/data/repositories/manager/payment_approval_repository.dart';
import 'package:mycondo/features/manager/widgets/payment_card.dart';

class ApprovePaymentsScreen extends StatefulWidget {
  const ApprovePaymentsScreen({super.key});

  @override
  State<ApprovePaymentsScreen> createState() => _ApprovePaymentsScreenState();
}

class _ApprovePaymentsScreenState extends State<ApprovePaymentsScreen> {
  final PaymentApprovalRepository _repository = PaymentApprovalRepository();
  PaymentStatus selectedTab = PaymentStatus.pending;
  late Future<List<PaymentItem>> _paymentsFuture;

  @override
  void initState() {
    super.initState();
    _paymentsFuture = _repository.getPayments(selectedTab);
  }

  Future<void> _loadPayments() async {
    final future = _repository.getPayments(selectedTab);
    setState(() {
      _paymentsFuture = future;
    });
    await future;
  }

  void _setSelectedTab(PaymentStatus status) {
    setState(() {
      selectedTab = status;
      _paymentsFuture = _repository.getPayments(selectedTab);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDDEFFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.chevron_left, color: Colors.black),
                  label: const Text(
                    'Back',
                    style: TextStyle(
                      fontFamily: "Urbanist",
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF4FB),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Approve Payments',
                        style: TextStyle(
                          fontFamily: "Urbanist",
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildTabs(),
                      const SizedBox(height: 14),
                      Expanded(
                        child: FutureBuilder<List<PaymentItem>>(
                          future: _paymentsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Unable to load payments: ${snapshot.error}',
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }

                            final payments =
                                snapshot.data ?? const <PaymentItem>[];
                            if (payments.isEmpty) {
                              return const Center(
                                child: Text(
                                  'No payments found.',
                                  style: TextStyle(
                                    fontFamily: "Urbanist",
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                    height: 1.0,
                                  ),
                                ),
                              );
                            }

                            return RefreshIndicator(
                              onRefresh: _loadPayments,
                              child: ListView.builder(
                                itemCount: payments.length,
                                itemBuilder: (context, index) {
                                  final payment = payments[index];
                                  return PaymentCard(
                                    payment: payment,
                                    onApprove: () => _approve(payment),
                                    onReject: () => _reject(payment),
                                  );
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _tabItem('Pending', PaymentStatus.pending),
          _tabItem('Approved', PaymentStatus.approved),
          _tabItem('Rejected', PaymentStatus.rejected),
        ],
      ),
    );
  }

  Widget _tabItem(String label, PaymentStatus status) {
    final isSelected = selectedTab == status;

    return GestureDetector(
      onTap: () => _setSelectedTab(status),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: "Urbanist",
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF53B1FD),
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2,
            width: isSelected ? 40 : 0,
            decoration: BoxDecoration(
              color: const Color(0xFF53B1FD),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approve(PaymentItem payment) async {
    try {
      await _repository.approvePayment(payment);
      await _loadPayments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approve failed: $e')),
      );
    }
  }

  Future<void> _reject(PaymentItem payment) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => const _RejectPaymentDialog(),
    );
    if (reason == null) return;

    try {
      await _repository.rejectPayment(
        payment: payment,
        reason: reason,
      );
      await _loadPayments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reject failed: $e')),
      );
    }
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

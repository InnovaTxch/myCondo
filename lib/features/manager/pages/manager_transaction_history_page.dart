import 'package:flutter/material.dart';
import 'package:mycondo/data/models/payment_item.dart';
import 'package:mycondo/data/repositories/manager/payment_approval_repository.dart';
import 'package:mycondo/features/manager/widgets/payment_card.dart';

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

  @override
  void initState() {
    super.initState();
    _paymentsFuture = _repository.getProcessedPayments();
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
      backgroundColor: const Color(0xFFF8F7F4),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Transaction History',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Approved and denied payments',
                style: TextStyle(color: Color(0xFF777777)),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<PaymentItem>>(
                  future: _paymentsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Unable to load transactions: ${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    final payments = snapshot.data ?? const <PaymentItem>[];
                    if (payments.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            Center(
                              child: Text(
                                'No processed payments yet.',
                                style: TextStyle(color: Color(0xFF777777)),
                              ),
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
                        itemCount: payments.length,
                        itemBuilder: (context, index) {
                          return PaymentCard(payment: payments[index]);
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
}

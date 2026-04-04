import 'package:flutter/material.dart';
import 'package:mycondo/data/models/payment_item.dart';
import 'package:mycondo/features/manager/widgets/payment_card.dart';

class ApprovePaymentsScreen extends StatefulWidget {
  const ApprovePaymentsScreen({super.key});

  @override
  State<ApprovePaymentsScreen> createState() => _ApprovePaymentsScreenState();
}

class _ApprovePaymentsScreenState extends State<ApprovePaymentsScreen> {
  PaymentStatus selectedTab = PaymentStatus.pending;

  final List<PaymentItem> allPayments =  [
    PaymentItem(
      residentName: 'John Smith',
      room: 'Rm 05',
      amount: '₱6,000.00',
      method: 'Pay via Scanned QR',
      date: 'Date: 01-19-26',
      status: PaymentStatus.pending,
    ),
    PaymentItem(
      residentName: 'Natasha Romanoff',
      room: 'Rm 01',
      amount: '₱3,000.00',
      method: 'Pay via Scanned QR',
      date: 'Date: 01-19-26',
      status: PaymentStatus.pending,
    ),
    PaymentItem(
      residentName: 'Robb Smith',
      room: 'Rm 05',
      amount: '₱3,000.00',
      method: 'Pay via Scanned QR',
      date: 'Date: 01-19-26',
      status: PaymentStatus.approved,
    ),
    PaymentItem(
      residentName: 'Lorelai Gilmore',
      room: 'Rm 01',
      amount: '₱3,000.00',
      method: 'Pay via Scanned QR',
      date: 'Date: 01-19-26',
      status: PaymentStatus.rejected,
    ),
  ];

  List<PaymentItem> get filteredPayments {
    return allPayments.where((payment) => payment.status == selectedTab).toList();
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
                  label: Text(
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
                      Text(
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
                        child: filteredPayments.isEmpty
                            ? const Center(
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
                        )
                            : ListView.builder(
                          itemCount: filteredPayments.length,
                          itemBuilder: (context, index) {
                            final payment = filteredPayments[index];

                            return PaymentCard(
                              payment: payment,
                              onApprove: () {
                                setState(() {
                                  payment.status = PaymentStatus.approved;
                                });
                              },
                              onReject: () {
                                setState(() {
                                  payment.status = PaymentStatus.rejected;
                                });
                              },
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
      onTap: () {
        setState(() {
          selectedTab = status;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
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
}
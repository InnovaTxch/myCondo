import 'package:flutter/material.dart';
import 'package:mycondo/features/manager/widgets/payment_history_card.dart';

class PaymentHistoryScreen extends StatelessWidget {
  PaymentHistoryScreen({super.key});

  final List<Map<String, dynamic>> paymentSections = [
    {
      'title': 'Yesterday',
      'items': [
        {
          'time': '1:49 AM',
          'label': '[Receive Money] John Smith',
          'amount': '+100.00',
        },
        {
          'time': '1:49 AM',
          'label': '[Receive Money] Natasha Romanoff',
          'amount': '+100.00',
        },
      ],
    },
    {
      'title': 'February 21, 2025',
      'items': [
        {
          'time': '1:49 AM',
          'label': '[Receive Money] Natasha Romanoff',
          'amount': '+100.00',
        },
        {
          'time': '1:49 AM',
          'label': '[Receive Money] Natasha Romanoff',
          'amount': '+100.00',
        },
        {
          'time': '1:49 AM',
          'label': '[Receive Money] Natasha Romanoff',
          'amount': '+100.00',
        },
        {
          'time': '1:49 AM',
          'label': '[Receive Money] Natasha Romanoff',
          'amount': '+100.00',
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDDF0FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.chevron_left,
                    color: Colors.black,
                    size: 20,
                  ),
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
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF4FB),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Payment History',
                        style: TextStyle(
                          fontFamily: "Urbanist",
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                          height: 1.0,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'As of Feb 8, 2026',
                        style: TextStyle(
                          fontFamily: "Urbanist",
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF8E8E8E),
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 18),

                      Expanded(
                        child: ListView(
                          children: paymentSections.map((section) {
                            final items = section['items'] as List<Map<String, dynamic>>;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  section['title'] as String,
                                  style: TextStyle(
                                    fontFamily: "Urbanist",
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF6D6D6D),
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                ...items.map(
                                      (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: PaymentHistoryCard(
                                      time: item['time'] as String,
                                      label: item['label'] as String,
                                      amount: item['amount'] as String,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 10),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

            ],
          ),
        ),
      ),
    );
  }
}

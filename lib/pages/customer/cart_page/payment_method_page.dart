import 'package:flutter/material.dart';

class PaymentMethodPage extends StatefulWidget {
  final Map<String, dynamic> selectedAddress;

  const PaymentMethodPage({
    super.key,
    required this.selectedAddress,
  });

  @override
  State<PaymentMethodPage> createState() =>
      _PaymentMethodPageState();
}

class _PaymentMethodPageState
    extends State<PaymentMethodPage> {
  String? selectedPaymentMethod;

  final List<Map<String, dynamic>> paymentMethods = [
    {
      'value': 'card',
      'title': 'Card',
      'subtitle': 'Pay using a card',
      'icon': Icons.credit_card,
    },
    {
      'value': 'e_wallet',
      'title': 'E-Wallet',
      'subtitle': 'Pay using an e-wallet',
      'icon': Icons.account_balance_wallet,
    },
    {
      'value': 'cash_on_delivery',
      'title': 'Cash on Delivery',
      'subtitle': 'Pay when your order arrives',
      'icon': Icons.payments,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Payment Method',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select Payment Method',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: paymentMethods.length,
                itemBuilder: (context, index) {
                  final method =
                      paymentMethods[index];

                  final String value =
                      method['value'];

                  return Card(
                    child: RadioListTile<String>(
                      value: value,
                      groupValue:
                          selectedPaymentMethod,
                      onChanged: (newValue) {
                        setState(() {
                          selectedPaymentMethod =
                              newValue;
                        });
                      },
                      secondary: Icon(
                        method['icon'],
                      ),
                      title: Text(
                        method['title'],
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        method['subtitle'],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    selectedPaymentMethod == null
                        ? null
                        : () {
                            Navigator.pop(
                              context,
                              selectedPaymentMethod,
                            );
                          },
                child: const Text(
                  'Continue',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
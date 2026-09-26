import 'package:flutter/material.dart';
import 'package:uaap_market/services/order_service.dart';

class OrderConfirmationPage extends StatefulWidget {
  final Map<String, dynamic> checkoutData;
  final double subtotal;
  final double deliveryFee;
  final double total;

  const OrderConfirmationPage({
    super.key,
    required this.checkoutData,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
  });

  @override
  State<OrderConfirmationPage> createState() => _OrderConfirmationPageState();
}

class _OrderConfirmationPageState extends State<OrderConfirmationPage> {
  final OrderService orderService = OrderService();

  bool isPlacingOrder = false;

  Future<void> placeOrder() async {
    if (isPlacingOrder) {
      return;
    }

    final address =
        widget.checkoutData['address']
            as Map<String, dynamic>;

    final paymentMethod =
        widget.checkoutData['payment_method']
            as String;

    setState(() {
      isPlacingOrder = true;
    });

    try {
      final orderId =
          await orderService.placeOrder(
        deliveryAddress:
            address['full_address'] ?? '',
        deliveryCity:
            address['city'] ?? '',
        deliveryProvince:
            address['province'] ?? '',
        deliveryPostalCode:
            address['postal_code'] ?? '',
        paymentMethod: paymentMethod,
        totalAmount: widget.total,
      );

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              'Order Placed',
            ),
            content: Text(
              'Your order has been placed successfully.\n\n'
              'Order ID:\n$orderId',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'OK',
                ),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      Navigator.popUntil(
        context,
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
        ),
      );

      setState(() {
        isPlacingOrder = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final address =
        widget.checkoutData['address']
            as Map<String, dynamic>;

    final paymentMethod =
        widget.checkoutData['payment_method']
            as String;

    String paymentLabel;

    switch (paymentMethod) {
      case 'card':
        paymentLabel = 'Card';
        break;

      case 'e_wallet':
        paymentLabel = 'E-Wallet';
        break;

      case 'cash_on_delivery':
        paymentLabel = 'Cash on Delivery';
        break;

      default:
        paymentLabel = paymentMethod;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Order Confirmation',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Delivery Address',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      address['label'] ?? 'Address',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      address['full_address'] ?? '',
                    ),

                    Text(
                      '${address['city']}, '
                      '${address['province']} '
                      '${address['postal_code']}',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.payment,
                ),
                title: Text(
                  paymentLabel,
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal'),
                        Text(
                          '₱${widget.subtotal.toStringAsFixed(2)}',
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Delivery Fee'),
                        Text(
                          '₱${widget.deliveryFee.toStringAsFixed(2)}',
                        ),
                      ],
                    ),

                    const Divider(height: 24),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₱${widget.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isPlacingOrder
                    ? null
                    : placeOrder,
                child: isPlacingOrder
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Place Order',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
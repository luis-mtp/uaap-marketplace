import 'package:flutter/material.dart';

class OrderDetailsPage extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderDetailsPage({
    super.key,
    required this.order,
  });

  String formatStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';

      case 'confirmed':
        return 'Confirmed';

      case 'packed':
        return 'Packed';

      case 'shipped':
        return 'Shipped';

      case 'delivered':
        return 'Delivered';

      case 'cancelled':
        return 'Cancelled';

      default:
        return status;
    }
  }

  String formatPaymentMethod(String method) {
    switch (method) {
      case 'card':
        return 'Card';

      case 'e_wallet':
        return 'E-Wallet';

      case 'cash_on_delivery':
        return 'Cash on Delivery';

      default:
        return method;
    }
  }

  Widget _buildProductImage(String imageUrl) {
    final isNetworkImage =
        imageUrl.startsWith('http://') ||
        imageUrl.startsWith('https://');

    if (isNetworkImage) {
      return Image.network(
        imageUrl,
        width: 70,
        height: 70,
        fit: BoxFit.cover,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return _imageErrorWidget();
        },
      );
    }

    return Image.asset(
      imageUrl,
      width: 70,
      height: 70,
      fit: BoxFit.cover,
      errorBuilder: (
        context,
        error,
        stackTrace,
      ) {
        return _imageErrorWidget();
      },
    );
  }

  Widget _imageErrorWidget() {
    return const SizedBox(
      width: 70,
      height: 70,
      child: Icon(
        Icons.image_not_supported,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderId = order['id']?.toString() ?? '';

    final shortOrderId =
        orderId.length >= 8
            ? orderId.substring(0, 8)
            : orderId;

    final status = order['status']?.toString() ?? '';

    final total =
        double.tryParse(
              order['total_amount']
                      ?.toString() ??
                  '0',
            ) ??
            0;

    final orderItems = order['order_items'] as List<dynamic>? ?? [];

    final payment = order['payments'] as Map<String, dynamic>?;

    final paymentMethod = payment?['method']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Order Details',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Order #$shortOrderId',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Status: ${formatStatus(status)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Products',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            ...orderItems.map(
              (item) {
                final itemData =
                    item as Map<String, dynamic>;

                final product =
                    itemData['products']
                            as Map<String, dynamic>? ??
                        {};

                final variant =
                    itemData['product_variants']
                            as Map<String, dynamic>?;

                final name =
                    product['name']
                            ?.toString() ??
                        'Product';

                final imageUrl =
                    product['image_url']
                            ?.toString() ??
                        '';

                final quantity =
                    itemData['quantity'] ?? 0;

                final unitPrice =
                    double.tryParse(
                          itemData[
                                      'unit_price']
                                  ?.toString() ??
                              '0',
                        ) ??
                        0;

                final size =
                    variant?['size']
                            ?.toString();

                return Card(
                  margin:
                      const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        if (imageUrl.isNotEmpty)
                          _buildProductImage(imageUrl)
                        else
                          const SizedBox(
                            width: 70,
                            height: 70,
                            child: Icon(
                              Icons
                                  .image_not_supported,
                            ),
                          ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                name,
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              if (size != null)
                                Text(
                                  'Size: $size',
                                ),

                              Text(
                                'Quantity: $quantity',
                              ),

                              Text(
                                '₱${unitPrice.toStringAsFixed(2)} each',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            const Divider(),

            const SizedBox(height: 16),

            const Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _summaryRow(
              'Total',
              '₱${total.toStringAsFixed(2)}',
              bold: true,
            ),

            const SizedBox(height: 24),

            const Text(
              'Payment',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              formatPaymentMethod(
                paymentMethod,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Delivery Address',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              order['delivery_name']
                      ?.toString() ??
                  '',
            ),

            Text(
              order['delivery_phone']
                      ?.toString() ??
                  '',
            ),

            const SizedBox(height: 4),

            Text(
              order['delivery_address']
                      ?.toString() ??
                  '',
            ),

            Text(
              '${order['delivery_city']}, '
              '${order['delivery_province']}',
            ),

            Text(
              order['delivery_postal_code']
                      ?.toString() ??
                  '',
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight:
                bold ? FontWeight.bold : null,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight:
                bold ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }
}
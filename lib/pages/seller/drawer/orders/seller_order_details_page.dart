import 'package:flutter/material.dart';
import 'package:uaap_market/services/seller/seller_order_service.dart';

class SellerOrderDetailsPage extends StatefulWidget {
  final Map<String, dynamic> order;

  const SellerOrderDetailsPage({
    super.key,
    required this.order,
  });

  @override
  State<SellerOrderDetailsPage> createState() =>
      _SellerOrderDetailsPageState();
}

class _SellerOrderDetailsPageState
    extends State<SellerOrderDetailsPage> {
  
  final SellerOrderService sellerOrderService =
    SellerOrderService();

  String? selectedStatus;

  bool isUpdatingStatus = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    selectedStatus =
        widget.order['status']?.toString() ?? 'pending';
  }

  Future<void> updateStatus() async {
    if (selectedStatus == null) return;

    final currentStatus =
        widget.order['status']?.toString() ?? 'pending';

    if (selectedStatus == currentStatus) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No status change was made.',
          ),
        ),
      );

      return;
    }

    setState(() {
      isUpdatingStatus = true;
    });

    try {
      await sellerOrderService.updateOrderStatus(
        orderId: widget.order['id'].toString(),
        status: selectedStatus!,
      );

      if (!mounted) return;

      setState(() {
        widget.order['status'] = selectedStatus;
        isUpdatingStatus = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Order status updated successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isUpdatingStatus = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update order status: $e',
          ),
        ),
      );
    }
  }

  String formatStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
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

  String formatDate(String? date) {
    if (date == null) return '';

    final parsedDate = DateTime.tryParse(date);

    if (parsedDate == null) return date;

    return '${parsedDate.month}/${parsedDate.day}/${parsedDate.year} '
        '${parsedDate.hour.toString().padLeft(2, '0')}:'
        '${parsedDate.minute.toString().padLeft(2, '0')}';
  }

  Future<void> refreshOrder() async {
    // The order data is already loaded from SellerOrdersPage.
    // This is kept so RefreshIndicator works like the Admin page.
    setState(() {
      isLoading = true;
    });

    await Future.delayed(
      const Duration(milliseconds: 300),
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    final orderId =
        order['id']?.toString() ?? '';

    final shortOrderId =
        orderId.length >= 8
            ? orderId.substring(0, 8)
            : orderId;

    /* final status =
        order['status']?.toString() ?? 'pending'; */

    final total =
        (order['total_amount'] as num?)
                ?.toDouble() ??
            0;

    final orderItems =
        order['order_items']
            as List<dynamic>? ??
        [];

    final payment =
        order['payments']
            as Map<String, dynamic>?;

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Order #$shortOrderId',
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Order #$shortOrderId',
        ),
      ),

      body: RefreshIndicator(
        onRefresh: refreshOrder,

        child: ListView(
          padding: const EdgeInsets.all(16),

          children: [

            // ORDER STATUS

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    const Text(
                      'Order Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,

                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Status',
                      ),

                      items: const [
                        DropdownMenuItem(
                          value: 'pending',
                          child: Text('Pending'),
                        ),

                        DropdownMenuItem(
                          value: 'confirmed',
                          child: Text('Confirmed'),
                        ),

                        DropdownMenuItem(
                          value: 'shipped',
                          child: Text('Shipped'),
                        ),

                        DropdownMenuItem(
                          value: 'delivered',
                          child: Text('Delivered'),
                        ),

                        DropdownMenuItem(
                          value: 'cancelled',
                          child: Text('Cancelled'),
                        ),
                      ],

                      onChanged: isUpdatingStatus
                          ? null
                          : (value) {
                              setState(() {
                                selectedStatus = value;
                              });
                            },
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,

                      child: ElevatedButton.icon(
                        onPressed:
                            isUpdatingStatus
                                ? null
                                : updateStatus,

                        icon: isUpdatingStatus
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.save_outlined,
                              ),

                        label: Text(
                          isUpdatingStatus
                              ? 'Updating...'
                              : 'Update Status',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // CUSTOMER / DELIVERY INFORMATION

            const Text(
              'Customer / Delivery Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      order['delivery_name']
                              ?.toString() ??
                          'Unknown',
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      order['delivery_phone']
                              ?.toString() ??
                          'No phone number',
                    ),

                    const SizedBox(height: 8),

                    Text(
                      order['delivery_address']
                              ?.toString() ??
                          '',
                    ),

                    Text(
                      '${order['delivery_city'] ?? ''}, '
                      '${order['delivery_province'] ?? ''}',
                    ),

                    Text(
                      order['delivery_postal_code']
                              ?.toString() ??
                          '',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ORDER ITEMS

            const Text(
              'Order Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            if (orderItems.isEmpty)
              const Card(
                child: Padding(
                  padding:
                      EdgeInsets.all(16),

                  child: Text(
                    'No order items found.',
                  ),
                ),
              )
            else
              ...orderItems.map(
                (item) {
                  final product =
                      item['products']
                          as Map<String, dynamic>?;

                  final variant =
                      item['product_variants']
                          as Map<String, dynamic>?;

                  final productName =
                      product?['name']
                              ?.toString() ??
                          'Unknown Product';

                  final size =
                      variant?['size']
                          ?.toString();

                  final quantity =
                      (item['quantity'] as num?)
                              ?.toInt() ??
                          0;

                  final unitPrice =
                      (item['unit_price'] as num?)
                              ?.toDouble() ??
                          0;

                  final subtotal =
                      unitPrice * quantity;

                  return Card(
                    margin:
                        const EdgeInsets.only(
                      bottom: 8,
                    ),

                    child: ListTile(
                      title: Text(
                        productName,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      subtitle: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
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

                      trailing: Text(
                        '₱${subtotal.toStringAsFixed(2)}',
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 16),

            // PAYMENT

            const Text(
              'Payment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(16),

                child: payment == null
                    ? const Text(
                        'No payment information found.',
                      )
                    : Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          Text(
                            'Method: ${formatPaymentMethod(
                              payment['method']
                                      ?.toString() ??
                                  '',
                            )}',
                          ),

                          const SizedBox(height: 6),

                          Text(
                            'Status: ${payment['status']
                                    ?.toString()
                                    .toUpperCase() ?? ''}',
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // TOTAL

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(16),

                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,

                  children: [
                    const Text(
                      'Order Total',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    Text(
                      '₱${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
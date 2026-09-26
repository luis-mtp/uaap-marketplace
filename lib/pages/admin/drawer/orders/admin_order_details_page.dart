import 'package:flutter/material.dart';
import 'package:uaap_market/services/admin_service.dart';

class AdminOrderDetailsPage extends StatefulWidget {
  final Map<String, dynamic> order;

  const AdminOrderDetailsPage({
    super.key,
    required this.order,
  });

  @override
  State<AdminOrderDetailsPage> createState() => _AdminOrderDetailsPageState();
}

class _AdminOrderDetailsPageState extends State<AdminOrderDetailsPage> {

  final AdminService adminService = AdminService();

  List<Map<String, dynamic>> orderItems = [];
  Map<String, dynamic>? payment;
  
  String? selectedStatus;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    selectedStatus = widget.order['status']?.toString() ?? 'pending';

    loadOrderDetails();
  }

  Future<void> loadOrderDetails() async {
    try {
      final items =
          await adminService.getOrderItems(
        widget.order['id'].toString(),
      );

      final paymentData =
          await adminService.getOrderPayment(
        widget.order['id'].toString(),
      );

      if (!mounted) return;

      setState(() {
        orderItems = items;
        payment = paymentData;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load order details: $e',
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

  Future<void> updateStatus() async {
    if (selectedStatus == null) return;

    try {
      await adminService.updateOrderStatus(
        orderId: widget.order['id'].toString(),
        status: selectedStatus!,
      );

      if (!mounted) return;

      setState(() {
        widget.order['status'] = selectedStatus;
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update order status: $e',
          ),
        ),
      );
    }
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

    final total =
        (order['total_amount'] as num?)
                ?.toDouble() ??
            0;

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
        onRefresh: loadOrderDetails,

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
                      value: selectedStatus,

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
                          value: 'packed',
                          child: Text('Packed'),
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

                      onChanged: (value) {
                        setState(() {
                          selectedStatus = value;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,

                      child: ElevatedButton.icon(
                        onPressed: updateStatus,

                        icon: const Icon(
                          Icons.save_outlined,
                        ),

                        label: const Text(
                          'Update Status',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // CUSTOMER INFORMATION

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
                padding: const EdgeInsets.all(16),

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
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No order items found.',
                  ),
                ),
              )
            else
              ...orderItems.map(
                (item) {
                  final productName =
                      item['products']?['name']
                              ?.toString() ??
                          'Unknown Product';

                  final size =
                      item['product_variants']?['size']
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
                    margin: const EdgeInsets.only(
                      bottom: 8,
                    ),

                    child: ListTile(
                      title: Text(
                        productName,
                        style: const TextStyle(
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
                        style: const TextStyle(
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
                padding: const EdgeInsets.all(16),

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
                              payment!['method']
                                      ?.toString() ??
                                  '',
                            )}',
                          ),

                          const SizedBox(height: 6),

                          Text(
                            'Status: ${payment!['status']
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
                padding: const EdgeInsets.all(16),

                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,

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
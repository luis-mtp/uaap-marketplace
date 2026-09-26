import 'package:flutter/material.dart';
import 'package:uaap_market/pages/customer/account_page/order_details_page.dart';
import 'package:uaap_market/services/order_service.dart';

class CustomerOrdersPage extends StatefulWidget {
  const CustomerOrdersPage({super.key});

  @override
  State<CustomerOrdersPage> createState() =>
      _CustomerOrdersPageState();
}

class _CustomerOrdersPageState
    extends State<CustomerOrdersPage> {
  final OrderService orderService = OrderService();

  List<Map<String, dynamic>> orders = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    try {
      final result =
          await orderService.getMyOrders();

      if (!mounted) return;

      setState(() {
        orders = result;
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
            'Failed to load orders: $e',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : orders.isEmpty
              ? RefreshIndicator(
                  onRefresh: loadOrders,
                  child: ListView(
                    children: const [
                      SizedBox(height: 180),
                      Center(
                        child: Text(
                          'You have no orders yet.',
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];

                      final orderId =
                          order['id'] ?? '';

                      final status =
                          order['status'] ?? '';

                      final total =
                          order['total_amount'] ?? 0;

                      final createdAt =
                          order['created_at'] ?? '';

                      final orderItems =
                          order['order_items']
                              as List<dynamic>? ??
                          [];

                      return Card(
                        margin:
                            const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    OrderDetailsPage(
                                  order: order,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding:
                                const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceBetween,
                                  children: [
                                    const Text(
                                      'Order',
                                      style: TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '#${orderId.toString().substring(0, 8)}',
                                      style:
                                          const TextStyle(
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                          
                                const SizedBox(height: 8),
                          
                                Text(
                                  createdAt.toString(),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                          
                                const SizedBox(height: 16),
                          
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceBetween,
                                  children: [
                                    const Text(
                                      'Status',
                                    ),
                                    Text(
                                      formatStatus(
                                        status.toString(),
                                      ),
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                          
                                const SizedBox(height: 8),
                          
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceBetween,
                                  children: [
                                    const Text(
                                      'Items',
                                    ),
                                    Text(
                                      '${orderItems.length}',
                                    ),
                                  ],
                                ),
                          
                                const SizedBox(height: 8),
                          
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceBetween,
                                  children: [
                                    const Text(
                                      'Total',
                                    ),
                                    Text(
                                      '₱${double.parse(total.toString()).toStringAsFixed(2)}',
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
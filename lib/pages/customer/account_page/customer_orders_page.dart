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

  List<Map<String, dynamic>> allOrders = [];
  List<Map<String, dynamic>> activeOrders = [];
  List<Map<String, dynamic>> completedOrders = [];
  List<Map<String, dynamic>> cancelledOrders = [];

  bool isLoading = true;

  int selectedTab = 0;

  String activeStatusFilter = 'all';

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    try {
      final result = await orderService.getMyOrders();

      final active = <Map<String, dynamic>>[];
      final completed = <Map<String, dynamic>>[];
      final cancelled = <Map<String, dynamic>>[];

      for (final order in result) {
        final status =
            order['status']?.toString() ?? '';

        switch (status) {
          case 'pending':
          case 'confirmed':
          case 'shipped':
            active.add(order);
            break;

          case 'delivered':
            completed.add(order);
            break;

          case 'cancelled':
            cancelled.add(order);
            break;
        }
      }

      if (!mounted) return;

      setState(() {
        allOrders = result;
        activeOrders = active;
        completedOrders = completed;
        cancelledOrders = cancelled;
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

  List<Map<String, dynamic>> getDisplayedOrders() {
    switch (selectedTab) {
      case 1:
        return completedOrders;

      case 2:
        return cancelledOrders;

      case 0:
      default:
        if (activeStatusFilter == 'all') {
          return activeOrders;
        }

        return activeOrders.where((order) {
          final status =
              order['status']?.toString() ?? '';

          return status == activeStatusFilter;
        }).toList();
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

  Widget _buildStatusBadge(String status) {
    IconData icon;

    switch (status) {
      case 'pending':
        icon = Icons.pending_outlined;
        break;

      case 'confirmed':
        icon = Icons.check_circle_outline;
        break;

      case 'shipped':
        icon = Icons.local_shipping_outlined;
        break;

      case 'delivered':
        icon = Icons.done_all;
        break;

      case 'cancelled':
        icon = Icons.cancel_outlined;
        break;

      default:
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            formatStatus(status),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    final displayedOrders = getDisplayedOrders();

    if (displayedOrders.isEmpty) {
      String message;

      switch (selectedTab) {
        case 1:
          message = 'No completed orders.';
          break;

        case 2:
          message = 'No cancelled orders.';
          break;

        case 0:
        default:
          message = 'No active orders.';
          break;
      }

      return RefreshIndicator(
        onRefresh: loadOrders,
        child: ListView(
          children: [
            const SizedBox(height: 180),
            Center(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: displayedOrders.length,
        itemBuilder: (context, index) {
          final order = displayedOrders[index];

          final orderId =
              order['id']?.toString() ?? '';

          final shortOrderId =
              orderId.length >= 8
                  ? orderId.substring(0, 8)
                  : orderId;

          final status =
              order['status']?.toString() ?? 'pending';

          final total =
              (order['total_amount'] as num?)
                      ?.toDouble() ??
                  0;

          final createdAt =
              order['created_at']?.toString() ?? '';

          final orderItems =
              order['order_items']
                      as List<dynamic>? ??
                  [];

          return Card(
            margin: const EdgeInsets.only(
              bottom: 12,
            ),
            child: InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        OrderDetailsPage(
                      order: order,
                    ),
                  ),
                );

                await loadOrders();
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
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
                          '#$shortOrderId',
                          style: const TextStyle(
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    if (createdAt.isNotEmpty)
                      Text(
                        createdAt.length >= 10
                            ? createdAt.substring(0, 10)
                            : createdAt,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),

                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Status',
                        ),
                        _buildStatusBadge(status),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
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
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                        ),
                        Text(
                          '₱${total.toStringAsFixed(2)}',
                          style: const TextStyle(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Orders',
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment<int>(
                        value: 0,
                        label: Text('Active'),
                        icon: Icon(
                          Icons.pending_actions_outlined,
                        ),
                      ),
                      ButtonSegment<int>(
                        value: 1,
                        label: Text('Completed'),
                        icon: Icon(
                          Icons.done_all,
                        ),
                      ),
                      ButtonSegment<int>(
                        value: 2,
                        label: Text('Cancelled'),
                        icon: Icon(
                          Icons.cancel_outlined,
                        ),
                      ),
                    ],
                    selected: {selectedTab},
                    onSelectionChanged:
                        (Set<int> selection) {
                      setState(() {
                        selectedTab =
                            selection.first;
                      });
                    },
                  ),
                ),

                if (selectedTab == 0)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child:
                        DropdownButtonFormField<String>(
                      initialValue:
                          activeStatusFilter,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Filter Active Orders',
                        border:
                            OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text(
                            'All Active',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'pending',
                          child: Text(
                            'Pending',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'confirmed',
                          child: Text(
                            'Confirmed',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'shipped',
                          child: Text(
                            'Shipped',
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          activeStatusFilter =
                              value;
                        });
                      },
                    ),
                  ),

                const SizedBox(height: 4),

                Expanded(
                  child: _buildOrderList(),
                ),
              ],
            ),
    );
  }
}
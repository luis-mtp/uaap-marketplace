import 'package:flutter/material.dart';
import 'package:uaap_market/pages/seller/drawer/orders/seller_order_details_page.dart';
import 'package:uaap_market/services/seller/seller_order_service.dart';


class SellerOrdersPage extends StatefulWidget {
  const SellerOrdersPage({super.key});

  @override
  State<SellerOrdersPage> createState() => _SellerOrdersPageState();
}

class _SellerOrdersPageState extends State<SellerOrdersPage> {
  final SellerOrderService sellerOrderService = SellerOrderService();

  List<Map<String, dynamic>> allOrders = [];
  List<Map<String, dynamic>> activeOrders = [];
  List<Map<String, dynamic>> completedOrders = [];
  List<Map<String, dynamic>> cancelledOrders = [];

  bool isLoading = true;

  int selectedTab = 0;

  String activeStatusFilter = 'All Active';

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    setState(() {
      isLoading = true;
    });

    try {
      final orders = await sellerOrderService.getMyOrders();

      final active = orders.where((order) {
        final status = order['status']?.toString();

        return status == 'pending' ||
            status == 'confirmed' ||
            status == 'shipped';
      }).toList();

      final completed = orders.where((order) {
        return order['status']?.toString() == 'delivered';
      }).toList();

      final cancelled = orders.where((order) {
        return order['status']?.toString() == 'cancelled';
      }).toList();

      if (!mounted) return;

      setState(() {
        allOrders = orders;
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
          content: Text('Failed to load orders: $e'),
        ),
      );
    }
  }

  List<Map<String, dynamic>> getDisplayedOrders() {
    List<Map<String, dynamic>> orders;

    if (selectedTab == 0) {
      orders = activeOrders;

      if (activeStatusFilter != 'All Active') {
        final status = activeStatusFilter.toLowerCase();

        orders = orders.where((order) {
          return order['status']?.toString() == status;
        }).toList();
      }
    } else if (selectedTab == 1) {
      orders = completedOrders;
    } else {
      orders = cancelledOrders;
    }

    return orders;
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
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey.shade100,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
          ),
          const SizedBox(width: 5),
          Text(
            formatStatus(status),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String formatDate(String? dateString) {
    if (dateString == null) return 'N/A';

    final date = DateTime.tryParse(dateString);

    if (date == null) return 'N/A';

    return '${date.month}/${date.day}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildOrderList() {
    final orders = getDisplayedOrders();

    if (orders.isEmpty) {
      return const Center(
        child: Text(
          'No orders found.',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];

        final orderId = order['id']?.toString() ?? '';
        final status = order['status']?.toString() ?? '';
        final total = order['total_amount'] ?? 0;

        final orderItems =
            order['order_items'] as List<dynamic>? ?? [];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SellerOrderDetailsPage(
                    order: order,
                  ),
                ),
              );

              await loadOrders();
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${orderId.length > 8 ? orderId.substring(0, 8) : orderId}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          order['delivery_name']?.toString() ??
                              'Customer',
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 8),

                        _buildStatusBadge(status),

                        const SizedBox(height: 8),

                        Text(
                          formatDate(
                            order['created_at']?.toString(),
                          ),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          '${orderItems.length} item${orderItems.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₱${double.tryParse(total.toString())?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadOrders,
          ),
        ],
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment<int>(
                          value: 0,
                          label: Text('Active'),
                        ),
                        ButtonSegment<int>(
                          value: 1,
                          label: Text('Completed'),
                        ),
                        ButtonSegment<int>(
                          value: 2,
                          label: Text('Cancelled'),
                        ),
                      ],
                      selected: {selectedTab},
                      onSelectionChanged: (Set<int> selection) {
                        setState(() {
                          selectedTab = selection.first;
                        });
                      },
                    ),
                  ),
                ),

                if (selectedTab == 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      4,
                    ),
                    child: DropdownButtonFormField<String>(
                      initialValue: activeStatusFilter,
                      decoration: const InputDecoration(
                        labelText: 'Filter Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'All Active',
                          child: Text('All Active'),
                        ),
                        DropdownMenuItem(
                          value: 'Pending',
                          child: Text('Pending'),
                        ),
                        DropdownMenuItem(
                          value: 'Confirmed',
                          child: Text('Confirmed'),
                        ),
                        DropdownMenuItem(
                          value: 'Shipped',
                          child: Text('Shipped'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          activeStatusFilter = value;
                        });
                      },
                    ),
                  ),

                const SizedBox(height: 8),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: loadOrders,
                    child: _buildOrderList(),
                  ),
                ),
              ],
            ),
    );
  }
}
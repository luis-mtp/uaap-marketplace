import 'package:flutter/material.dart';
import 'package:uaap_market/services/seller/seller_service.dart';

class SellerSalesPage extends StatefulWidget {
  const SellerSalesPage({super.key});

  @override
  State<SellerSalesPage> createState() => _SellerSalesPageState();
}

class _SellerSalesPageState extends State<SellerSalesPage> {
  final SellerService sellerService = SellerService();

  bool isLoading = true;

  double totalSales = 0;
  int totalOrders = 0;
  int completedOrders = 0;
  double averageOrderValue = 0;

  int pendingOrders = 0;
  int confirmedOrders = 0;
  int shippedOrders = 0;
  int deliveredOrders = 0;
  int cancelledOrders = 0;

  List<Map<String, dynamic>> salesHistory = [];

  @override
  void initState() {
    super.initState();
    loadSales();
  }

  Future<void> loadSales() async {
    try {
      final sales = await sellerService.getSales();

      if (!mounted) return;

      final history =
          List<Map<String, dynamic>>.from(
        sales['sales_history'] ?? [],
      );

      final nonCancelledOrders =
          (sales['total_orders'] as num?)?.toInt() ?? 0;

      final totalSalesValue =
          (sales['total_sales'] as num?)?.toDouble() ?? 0;

      setState(() {
        totalSales = totalSalesValue;

        totalOrders = nonCancelledOrders;

        completedOrders =
            (sales['completed_orders'] as num?)?.toInt() ?? 0;

        averageOrderValue = totalOrders > 0
            ? totalSales / totalOrders
            : 0;

        pendingOrders =
            (sales['pending_orders'] as num?)?.toInt() ?? 0;

        confirmedOrders =
            (sales['confirmed_orders'] as num?)?.toInt() ?? 0;

        shippedOrders =
            (sales['shipped_orders'] as num?)?.toInt() ?? 0;

        deliveredOrders =
            (sales['delivered_orders'] as num?)?.toInt() ?? 0;

        cancelledOrders =
            (sales['cancelled_orders'] as num?)?.toInt() ?? 0;

        salesHistory = history;

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
            'Failed to load sales: $e',
          ),
        ),
      );
    }
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(
    String title,
    int count,
    IconData icon,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Text(
          count.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSalesHistoryRow(
    Map<String, dynamic> sale,
  ) {
    final orderId = sale['id']?.toString() ?? '';

    final shortOrderId = orderId.length > 8
        ? orderId.substring(0, 8)
        : orderId;

    final customer =
        sale['delivery_name']?.toString() ?? 'Customer';

    final status =
        sale['status']?.toString() ?? 'unknown';

    final amount =
        (sale['total_amount'] as num?)?.toDouble() ?? 0;

    final createdAt =
        sale['created_at']?.toString() ?? '';

    DateTime? date;

    try {
      date = DateTime.parse(createdAt);
    } catch (_) {
      date = null;
    }

    final formattedDate = date == null
        ? createdAt
        : '${date.month}/${date.day}/${date.year}';

    return Card(
      child: ListTile(
        leading: const Icon(
          Icons.receipt_long_outlined,
        ),
        title: Text(
          'Order #$shortOrderId',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(customer),
            Text(formattedDate),
            Text(
              status.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Text(
          '₱${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadSales,
              child: SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sales Summary',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'Total Sales',
                            value:
                                '₱${totalSales.toStringAsFixed(2)}',
                            icon:
                                Icons.payments_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'Total Orders',
                            value:
                                totalOrders.toString(),
                            icon:
                                Icons.shopping_bag_outlined,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'Completed Orders',
                            value:
                                completedOrders.toString(),
                            icon:
                                Icons.check_circle_outline,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'Delivered Sales',
                            value:
                                '₱${_getCompletedSales().toStringAsFixed(2)}',
                            icon:
                                Icons.done_all,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: _buildSummaryCard(
                        title: 'Average Order Value',
                        value:
                            '₱${averageOrderValue.toStringAsFixed(2)}',
                        icon:
                            Icons.analytics_outlined,
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Order Status',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _buildStatusRow(
                      'Pending',
                      pendingOrders,
                      Icons.pending_outlined,
                    ),

                    _buildStatusRow(
                      'Confirmed',
                      confirmedOrders,
                      Icons.check_circle_outline,
                    ),

                    _buildStatusRow(
                      'Shipped',
                      shippedOrders,
                      Icons.local_shipping_outlined,
                    ),

                    _buildStatusRow(
                      'Delivered',
                      deliveredOrders,
                      Icons.done_all,
                    ),

                    _buildStatusRow(
                      'Cancelled',
                      cancelledOrders,
                      Icons.cancel_outlined,
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Sales History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (salesHistory.isEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: Card(
                          child: Padding(
                            padding:
                                const EdgeInsets.all(16),
                            child: const Text(
                              'No sales yet.',
                            ),
                          ),
                        ),
                      )
                    else
                      ...salesHistory.map(
                        (sale) =>
                            _buildSalesHistoryRow(
                          sale,
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  double _getCompletedSales() {
    double total = 0;

    for (final sale in salesHistory) {
      if (sale['status'] == 'delivered') {
        total +=
            (sale['total_amount'] as num?)
                    ?.toDouble() ??
                0;
      }
    }

    return total;
  }
}
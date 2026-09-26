import 'package:flutter/material.dart';
import 'package:uaap_market/services/admin_service.dart';

class AdminSalesPage extends StatefulWidget {
  const AdminSalesPage({super.key});

  @override
  State<AdminSalesPage> createState() => _AdminSalesPageState();
}

class _AdminSalesPageState extends State<AdminSalesPage> {
  final AdminService adminService = AdminService();

  bool isLoading = true;

  double totalSales = 0;
  int totalOrders = 0;
  int completedOrders = 0;
  double averageOrderValue = 0;
  int totalItemsSold = 0;

  int pendingOrders = 0;
  int confirmedOrders = 0;
  int packedOrders = 0;
  int shippedOrders = 0;
  int deliveredOrders = 0;
  int cancelledOrders = 0;

  List<Map<String, dynamic>> salesByTeam = [];
  List<Map<String, dynamic>> topSellingProducts = [];

  @override
  void initState() {
    super.initState();
    loadSalesSummary();
  }

  Future<void> loadSalesSummary() async {
    try {
      final summary =
          await adminService.getSalesSummary();

      final teamSales =
          await adminService.getSalesByTeam();
      
      final productSales =
          await adminService.getTopSellingProducts();

      if (!mounted) return;

      setState(() {
        totalSales =
            (summary['total_sales'] as num?)
                    ?.toDouble() ??
                0;

        totalOrders =
            summary['total_orders'] ?? 0;

        completedOrders =
            summary['completed_orders'] ?? 0;

        averageOrderValue =
            (summary['average_order_value']
                        as num?)
                    ?.toDouble() ??
                0;

        totalItemsSold =
            summary['total_items_sold'] ?? 0;

        pendingOrders =
            summary['pending_orders'] ?? 0;

        confirmedOrders =
            summary['confirmed_orders'] ?? 0;

        packedOrders =
            summary['packed_orders'] ?? 0;

        shippedOrders =
            summary['shipped_orders'] ?? 0;

        deliveredOrders =
            summary['delivered_orders'] ?? 0;

        cancelledOrders =
            summary['cancelled_orders'] ?? 0;

        salesByTeam = teamSales;

        topSellingProducts = productSales;

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

  Widget _buildTeamSalesRow(
    String team,
    double sales,
  ) {
    return Card(
      child: ListTile(
        leading: const Icon(
          Icons.groups_outlined,
        ),
        title: Text(team),
        trailing: Text(
          '₱${sales.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildProductSalesRow(
    String product,
    int quantity,
    double sales,
  ) {
    return Card(
      child: ListTile(
        leading: const Icon(
          Icons.shopping_bag_outlined,
        ),
        title: Text(
          product,
        ),
        subtitle: Text(
          '$quantity sold',
        ),
        trailing: Text(
          '₱${sales.toStringAsFixed(2)}',
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
              onRefresh: loadSalesSummary,
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
                                completedOrders
                                    .toString(),
                            icon:
                                Icons.check_circle_outline,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: _buildSummaryCard(
                            title: 'Items Sold',
                            value:
                                totalItemsSold
                                    .toString(),
                            icon:
                                Icons.inventory_2_outlined,
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
                      'Packed',
                      packedOrders,
                      Icons.inventory_2_outlined,
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
                      'Sales by UAAP Team',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (salesByTeam.isEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: const Text(
                              'No delivered sales yet.',
                            ),
                          ),
                        ),
                      )
                    else
                      ...salesByTeam.map(
                        (team) => _buildTeamSalesRow(
                          team['team'].toString(),
                          (team['sales'] as num).toDouble(),
                        ),
                      ),

                    const SizedBox(height: 24),

                    const Text(
                      'Top-Selling Products',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (topSellingProducts.isEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: const Text(
                              'No delivered product sales yet.',
                            ),
                          ),
                        ),
                      )
                    else
                      ...topSellingProducts.map(
                        (product) => _buildProductSalesRow(
                          product['product'].toString(),
                          (product['quantity'] as num).toInt(),
                          (product['sales'] as num).toDouble(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
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
}
import 'package:flutter/material.dart';
import 'package:uaap_market/pages/auth/login_page.dart';
import 'package:uaap_market/pages/customer/customer_home_page.dart';
import 'package:uaap_market/pages/seller/drawer/products/seller_deleted_products_page.dart';
import 'package:uaap_market/pages/seller/drawer/orders/seller_orders_page.dart';
import 'package:uaap_market/pages/seller/drawer/seller_sales_page.dart';
import 'package:uaap_market/services/auth_services.dart';
import 'package:uaap_market/services/seller/seller_service.dart';
import 'package:uaap_market/pages/seller/drawer/products/seller_products_page.dart';

class SellerHomePage extends StatefulWidget {
  const SellerHomePage({super.key});

  @override
  State<SellerHomePage> createState() =>
      _SellerHomePageState();
}

class _SellerHomePageState
    extends State<SellerHomePage> {
  final SellerService sellerService =
      SellerService();

  final AuthService authService =
      AuthService();

  bool isLoading = true;

  double totalSales = 0;
  int totalOrders = 0;
  int pendingOrders = 0;
  int completedOrders = 0;
  int productCount = 0;

  List<Map<String, dynamic>> recentOrders = [];

  @override
  void initState() {
    super.initState();
    refreshDashboard();
  }

  Future<void> refreshDashboard() async {
    try {
      final stats =
          await sellerService.getDashboardStats();

      final sales =
          await sellerService.getSales();

      final orders =
          await sellerService.getRecentOrders();

      if (!mounted) return;

      setState(() {
        totalSales =
            (stats['total_sales'] as num?)
                    ?.toDouble() ??
                0;

        totalOrders =
          (sales['total_orders'] as num?)
                  ?.toInt() ??
              0;

        pendingOrders =
            (stats['pending_orders'] as num?)
                    ?.toInt() ??
                0;

        completedOrders =
            (stats['completed_orders'] as num?)
                    ?.toInt() ??
                0;

        productCount =
            (stats['products'] as num?)
                    ?.toInt() ??
                0;

        recentOrders = orders;

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
            'Failed to load dashboard: $e',
          ),
        ),
      );
    }
  }

  Future<void> logout() async {
    try {
      await authService.logout();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Logout failed: $e',
          ),
        ),
      );
    }
  }

  Widget _buildSellerDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisAlignment:
                  MainAxisAlignment.end,
              children: [
                Text(
                  'Seller Store',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          ListTile(
            leading: const Icon(
              Icons.dashboard_outlined,
            ),
            title: const Text(
              'Dashboard',
            ),
            selected: true,
            onTap: () {
              Navigator.pop(context);
            },
          ),

          ListTile(
            leading: const Icon(
              Icons.inventory_2_outlined,
            ),
            title: const Text(
              'Products & Inventory',
            ),
            onTap: () async {
              Navigator.pop(context);

              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const SellerProductsPage(),
                ),
              );

              await refreshDashboard();
            },
          ),

          ListTile(
            leading: const Icon(
              Icons.shopping_bag_outlined,
            ),
            title: const Text(
              'Orders',
            ),
            onTap: () async {
              Navigator.pop(context);

              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SellerOrdersPage(),
                ),
              );

              if (mounted) {
                refreshDashboard();
              }
            },
          ),

          ListTile(
            leading: const Icon(
              Icons.analytics_outlined,
            ),
            title: const Text(
              'Sales',
            ),
            onTap: () {
              Navigator.pop(context);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const SellerSalesPage(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.shopping_bag_outlined),
            title: const Text('Return to Customer'),
            onTap: () {
              Navigator.pop(context);

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const CustomerHomePage(),
                ),
              );
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(
              Icons.delete_outline,
            ),
            title: const Text(
              'Deleted Products',
            ),
            onTap: () {
              Navigator.pop(context);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const SellerDeletedProductsPage(),
                ),
              );
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(
              Icons.logout,
            ),
            title: const Text(
              'Logout',
            ),
            onTap: logout,
          ),
        ],
      ),
    );
  }

  String _formatOrderDate(dynamic value) {
    final date =
        DateTime.tryParse(
      value?.toString() ?? '',
    );

    if (date == null) {
      return 'Unknown date';
    }

    return date.toString().substring(0, 10);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildSellerDrawer(),

      appBar: AppBar(
        title: const Text(
          'Seller Dashboard',
        ),
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: refreshDashboard,

              child: SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),

                padding:
                    const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Card(
                      child: Padding(
                        padding:
                            const EdgeInsets.all(16),

                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 24,
                              child: Icon(
                                Icons.store_outlined,
                              ),
                            ),

                            const SizedBox(
                              width: 12,
                            ),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [
                                  const Text(
                                    'Welcome, Seller',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 4,
                                  ),

                                  Text(
                                    'UAAP Marketplace Store',
                                    style: TextStyle(
                                      color:
                                          Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    const Text(
                      'Sales Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title:
                                'Total Sales',
                            value:
                                '₱${totalSales.toStringAsFixed(2)}',
                            icon:
                                Icons.payments_outlined,
                          ),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        Expanded(
                          child: _buildStatCard(
                            title:
                                'Total Orders',
                            value:
                                totalOrders.toString(),
                            icon:
                                Icons.shopping_bag_outlined,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title:
                                'Pending Orders',
                            value:
                                pendingOrders.toString(),
                            icon:
                                Icons.pending_actions_outlined,
                          ),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        Expanded(
                          child: _buildStatCard(
                            title:
                                'Completed Orders',
                            value:
                                completedOrders.toString(),
                            icon:
                                Icons.check_circle_outline,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 32,
                    ),

                    const Text(
                      'Recent Orders',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    if (recentOrders.isEmpty)
                      Card(
                        child: Padding(
                          padding:
                              const EdgeInsets.all(20),

                          child: Center(
                            child: Text(
                              'No orders yet.',
                              style: TextStyle(
                                color:
                                    Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Column(
                        children:
                            recentOrders.map(
                          (order) {
                            final orderId =
                                order['id']
                                        ?.toString() ??
                                    '';

                            final shortOrderId =
                                orderId.length >= 8
                                    ? orderId
                                        .substring(
                                        0,
                                        8,
                                      )
                                    : orderId;

                            final status =
                                order['status']
                                        ?.toString() ??
                                    '';

                            final amount =
                                (order[
                                            'total_amount']
                                        as num?)
                                    ?.toDouble() ??
                                    0;

                            final createdAt =
                                order[
                                        'created_at'];

                            return Card(
                              margin:
                                  const EdgeInsets
                                      .only(
                                bottom: 10,
                              ),

                              child: ListTile(
                                leading:
                                    const Icon(
                                  Icons
                                      .shopping_bag_outlined,
                                ),

                                title: Text(
                                  'Order #$shortOrderId',
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),

                                subtitle:
                                    Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,

                                  children: [
                                    const SizedBox(
                                      height: 4,
                                    ),

                                    Text(
                                      _formatOrderDate(
                                        createdAt,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 4,
                                    ),

                                    Text(
                                      status
                                          .toUpperCase(),
                                    ),
                                  ],
                                ),

                                trailing:
                                    Text(
                                  '₱${amount.toStringAsFixed(2)}',
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ).toList(),
                      ),

                    const SizedBox(
                      height: 32,
                    ),

                    const Text(
                      'Quick Statistics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading:
                                const Icon(
                              Icons
                                  .inventory_2_outlined,
                            ),

                            title:
                                const Text(
                              'Products',
                            ),

                            trailing:
                                Row(
                              mainAxisSize:
                                  MainAxisSize.min,

                              children: [
                                Text(
                                  productCount
                                      .toString(),

                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),

                                const SizedBox(
                                  width: 8,
                                ),

                                const Icon(
                                  Icons
                                      .chevron_right,
                                ),
                              ],
                            ),

                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const SellerProductsPage(),
                                ),
                              );

                              await refreshDashboard();
                            },
                          ),

                          const Divider(
                            height: 1,
                          ),

                          ListTile(
                            leading:
                                const Icon(
                              Icons
                                  .shopping_bag_outlined,
                            ),

                            title:
                                const Text(
                              'Orders',
                            ),

                            trailing:
                                Row(
                              mainAxisSize:
                                  MainAxisSize.min,

                              children: [
                                Text(
                                  totalOrders
                                      .toString(),

                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),

                                const SizedBox(
                                  width: 8,
                                ),

                                const Icon(
                                  Icons
                                      .chevron_right,
                                ),
                              ],
                            ),

                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SellerOrdersPage(),
                                ),
                              );

                              if (mounted) {
                                refreshDashboard();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Icon(
              icon,
              size: 28,
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
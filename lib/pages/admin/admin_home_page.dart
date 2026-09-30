import 'package:flutter/material.dart';
import 'package:uaap_market/pages/admin/admin_users_page.dart';
import 'package:uaap_market/pages/admin/drawer/account/admin_account_page.dart';
import 'package:uaap_market/pages/admin/drawer/admin_seller_applications_page.dart';
import 'package:uaap_market/pages/admin/drawer/products/admin_deleted_products_page.dart';
import 'package:uaap_market/pages/admin/drawer/orders/admin_orders_page.dart';
import 'package:uaap_market/pages/admin/drawer/admin_products_page.dart';
import 'package:uaap_market/pages/admin/drawer/sales/admin_sales_page.dart';
import 'package:uaap_market/pages/auth/login_page.dart';
import 'package:uaap_market/services/admin/admin_service.dart';
import 'package:uaap_market/services/auth_services.dart';
//import 'package:uaap_market/pages/auth/login_page.dart';
//import 'package:uaap_market/services/auth_services.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() =>
      _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {

  final AdminService adminService = AdminService();
  final AuthService authService = AuthService();

  bool isLoading = true;

  double totalSales = 0;
  int totalOrders = 0;
  int pendingOrders = 0;
  int completedOrders = 0;

  List<Map<String, dynamic>> recentOrders = [];

  int productCount = 0;
  int customerCount = 0;
  int lowStockCount = 0;

  @override
  void initState() {
    super.initState();

    refreshDashboard();
  }

  Future<void> refreshDashboard() async {
    try {
      final stats =
          await adminService.getDashboardStats();

      final orders =
          await adminService.getRecentOrders();

      final quickStats =
          await adminService.getQuickStatistics();

      if (!mounted) return;

      setState(() {
        totalSales =
            stats['total_sales'] ?? 0;

        totalOrders =
            stats['total_orders'] ?? 0;

        pendingOrders =
            stats['pending_orders'] ?? 0;

        completedOrders =
            stats['completed_orders'] ?? 0;

        recentOrders = orders;

        productCount =
            quickStats['products'] ?? 0;

        customerCount =
            quickStats['customers'] ?? 0;

        lowStockCount =
            quickStats['low_stock'] ?? 0;

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

  Widget _buildAdminDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisAlignment:
                  MainAxisAlignment.end,
              children: const [
                Icon(
                  Icons.admin_panel_settings,
                  size: 40,
                ),

                SizedBox(height: 8),

                Text(
                  'Admin Panel',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'UAAP Merchandise',
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
            onTap: () {
              Navigator.pop(context);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const AdminProductsPage(),
                ),
              );
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
                  builder: (context) =>
                      const AdminOrdersPage(),
                ),
              );

              await refreshDashboard();
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
                      const AdminSalesPage(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(
              Icons.store_outlined,
            ),
            title: const Text(
              'Seller Applications',
            ),
            onTap: () {
              Navigator.pop(context);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const AdminSellerApplicationsPage(),
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
                  builder: (context) =>
                      const AdminDeletedProductsPage(),
                ),
              );
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(
              Icons.person_2_outlined,
            ),
            title: const Text(
              'Account',
            ),
            onTap: () {
              Navigator.pop(context);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const AdminAccountPage(),
                ),
              );
            },
          ),

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildAdminDrawer(),

      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
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

          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        child: Icon(
                          Icons.admin_panel_settings_outlined,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome, Admin',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              'UAAP Marketplace Manager',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Sales Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [

                  Expanded(
                    child: _buildStatCard(
                      title: 'Total Sales',
                      value: '₱${totalSales.toStringAsFixed(2)}',
                      icon: Icons
                          .payments_outlined,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _buildStatCard(
                      title: 'Total Orders',
                      value: totalOrders.toString(),
                      icon: Icons
                          .shopping_bag_outlined,
                    ),
                  ),

                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [

                  Expanded(
                    child: _buildStatCard(
                      title: 'Pending Orders',
                      value: pendingOrders.toString(),
                      icon: Icons
                          .pending_actions_outlined,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _buildStatCard(
                      title: 'Completed Orders',
                      value: completedOrders.toString(),
                      icon: Icons
                          .check_circle_outline,
                    ),
                  ),

                ],
              ),

              const SizedBox(height: 32),

              const Text(
                'Recent Orders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              if (recentOrders.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'No orders yet.',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: recentOrders.map((order) {
                    final orderId =
                        order['id']?.toString() ?? '';

                    final shortOrderId =
                        orderId.length >= 8
                            ? orderId.substring(0, 8)
                            : orderId;

                    final status =
                        order['status']?.toString() ?? '';

                    final amount =
                        (order['total_amount'] as num?)
                                ?.toDouble() ??
                            0;

                    final createdAt =
                        order['created_at']?.toString() ?? '';

                    return Card(
                      margin: const EdgeInsets.only(
                        bottom: 10,
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.shopping_bag_outlined,
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

                            Text(
                              createdAt.isNotEmpty
                                  ? createdAt.substring(
                                      0,
                                      10,
                                    )
                                  : 'Unknown date',
                            ),

                            const SizedBox(height: 4),

                            Text(
                              status.toUpperCase(),
                            ),
                          ],
                        ),

                        trailing: Text(
                          '₱${amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 32),

              const Text(
                'Quick Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Card(
                child: Column(
                  children: [

                    ListTile(
                      leading: const Icon(
                        Icons.inventory_2_outlined,
                      ),
                      title: const Text(
                        'Products',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            productCount.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right,
                          ),
                        ],
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AdminProductsPage(),
                          ),
                        );

                        await refreshDashboard();
                      },
                    ),

                    const Divider(height: 1),

                    ListTile(
                      leading: const Icon(
                        Icons.people_outline,
                      ),
                      title: const Text(
                        'Users',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            customerCount.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right,
                          ),
                        ],
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AdminUsersPage(),
                          ),
                        );

                        await refreshDashboard();
                      },
                    ),

                    const Divider(height: 1),

                    ListTile(
                      leading: const Icon(
                        Icons.warning_amber_outlined,
                      ),
                      title: const Text(
                        'Low Stock',
                      ),
                      trailing: Text(
                        lowStockCount.toString(),
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
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
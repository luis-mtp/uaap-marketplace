import 'package:flutter/material.dart';
import 'package:uaap_market/pages/auth/login_page.dart';
import 'package:uaap_market/pages/customer/account_page/account_information_page.dart';
import 'package:uaap_market/pages/customer/account_page/addresses_page.dart';
import 'package:uaap_market/pages/customer/account_page/customer_orders_page.dart';
import 'package:uaap_market/services/auth_services.dart';

class CustomerAccountPage extends StatefulWidget {
  const CustomerAccountPage({super.key});

  @override
  State<CustomerAccountPage> createState() =>
      _CustomerAccountPageState();
}

class _CustomerAccountPageState
    extends State<CustomerAccountPage> {
  final AuthService authService = AuthService();

  String fullName = '';

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final profile =
          await authService.getUserProfile();

      if (profile != null) {
        setState(() {
          fullName =
              profile['full_name'] ?? '';
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load account: $e',
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          Text(
            'Hello, $fullName',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          ListTile(
            leading: const Icon(
              Icons.person_outline,
            ),
            title: const Text(
              'Account Information',
            ),
            subtitle: const Text(
              'View and edit your personal information',
            ),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const AccountInformationPage(),
                ),
              );

              loadProfile();
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(
              Icons.location_on_outlined,
            ),
            title: const Text(
              'Addresses',
            ),
            subtitle: const Text(
              'Manage your delivery addresses',
            ),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const AddressesPage(),
                ),
              );
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(
              Icons.receipt_long_outlined,
            ),
            title: const Text(
              'Orders',
            ),
            subtitle: const Text(
              'View your orders and order status',
            ),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const CustomerOrdersPage(),
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
}
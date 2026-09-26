import 'package:flutter/material.dart';
import 'package:uaap_market/pages/auth/login_page.dart';
import 'package:uaap_market/pages/customer/account_page/change_password_page.dart';
import 'package:uaap_market/services/auth_services.dart';

class AdminAccountPage extends StatefulWidget {
  const AdminAccountPage({super.key});

  @override
  State<AdminAccountPage> createState() => _AdminAccountPageState();
}

class _AdminAccountPageState extends State<AdminAccountPage> {
  final AuthService authService = AuthService();

  final fullNameController =
      TextEditingController();

  String email = '';
  String role = '';

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    super.dispose();
  }

  Future<void> loadProfile() async {
    try {
      final profile =
          await authService.getUserProfile();

      if (profile == null) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });

        return;
      }

      fullNameController.text =
          profile['full_name'] ?? '';

      if (!mounted) return;

      setState(() {
        email = profile['email'] ?? '';
        role = profile['role'] ?? '';
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
            'Failed to load account information: $e',
          ),
        ),
      );
    }
  }

  Future<void> saveChanges() async {
    if (fullNameController.text
        .trim()
        .isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your full name.',
          ),
        ),
      );

      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await authService.updateUserProfile(
        fullName:
            fullNameController.text.trim(),
        phone: '',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Account information updated successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update account: $e',
          ),
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      isSaving = false;
    });
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
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Account',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller:
                  fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller:
                  TextEditingController(
                text: email,
              ),
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller:
                  TextEditingController(
                text: role,
              ),
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    isSaving
                        ? null
                        : saveChanges,
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                      ),
              ),
            ),

            const SizedBox(height: 32),

            const Divider(),

            const SizedBox(height: 16),

            const Text(
              'Security',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            ListTile(
              leading: const Icon(
                Icons.lock_outline,
              ),
              title: const Text(
                'Change Password',
              ),
              subtitle: const Text(
                'Update your account password',
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const ChangePasswordPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
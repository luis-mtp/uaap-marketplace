import 'package:flutter/material.dart';
import 'package:uaap_market/services/auth_services.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() =>
      _ChangePasswordPageState();
}

class _ChangePasswordPageState
    extends State<ChangePasswordPage> {
  final AuthService authService = AuthService();

  final currentPasswordController =
      TextEditingController();

  final newPasswordController =
      TextEditingController();

  final confirmPasswordController =
      TextEditingController();

  bool isChangingPassword = false;

  bool hideCurrentPassword = true;
  bool hideNewPassword = true;
  bool hideConfirmPassword = true;

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  Future<void> changePassword() async {
    final currentPassword =
        currentPasswordController.text;

    final newPassword =
        newPasswordController.text;

    final confirmPassword =
        confirmPasswordController.text;

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill in all fields.',
          ),
        ),
      );

      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'New password must be at least 6 characters.',
          ),
        ),
      );

      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'New passwords do not match.',
          ),
        ),
      );

      return;
    }

    if (currentPassword == newPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'New password must be different from your current password.',
          ),
        ),
      );

      return;
    }

    setState(() {
      isChangingPassword = true;
    });

    try {
      await authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (!mounted) return;

      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password changed successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      String message = e.toString();

      if (message.contains(
        'Invalid login credentials',
      )) {
        message =
            'Current password is incorrect.';
      } else {
        message = message.replaceFirst(
          'Exception: ',
          '',
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      isChangingPassword = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Change Password',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Change Password',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Enter your current password and choose a new password.',
            ),

            const SizedBox(height: 24),

            TextField(
              controller:
                  currentPasswordController,
              obscureText:
                  hideCurrentPassword,
              decoration: InputDecoration(
                labelText:
                    'Current Password',
                border:
                    const OutlineInputBorder(),
                suffixIcon:
                    IconButton(
                  icon: Icon(
                    hideCurrentPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      hideCurrentPassword =
                          !hideCurrentPassword;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller:
                  newPasswordController,
              obscureText:
                  hideNewPassword,
              decoration: InputDecoration(
                labelText:
                    'New Password',
                helperText:
                    'At least 6 characters',
                border:
                    const OutlineInputBorder(),
                suffixIcon:
                    IconButton(
                  icon: Icon(
                    hideNewPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      hideNewPassword =
                          !hideNewPassword;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller:
                  confirmPasswordController,
              obscureText:
                  hideConfirmPassword,
              decoration: InputDecoration(
                labelText:
                    'Confirm New Password',
                border:
                    const OutlineInputBorder(),
                suffixIcon:
                    IconButton(
                  icon: Icon(
                    hideConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      hideConfirmPassword =
                          !hideConfirmPassword;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    isChangingPassword
                        ? null
                        : changePassword,
                child: isChangingPassword
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Change Password',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
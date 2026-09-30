import 'package:flutter/material.dart';
import 'package:uaap_market/services/admin/admin_service.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final AdminService adminService = AdminService();

  List<Map<String, dynamic>> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    try {
      final data =
          await adminService.getAllUsers();

      if (!mounted) return;

      setState(() {
        users = data;
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
            'Failed to load users: $e',
          ),
        ),
      );
    }
  }

  Future<void> changeUserStatus(
    Map<String, dynamic> user,
  ) async {
    final bool currentStatus =
        user['is_active'] ?? true;

    final bool newStatus = !currentStatus;

    try {
      await adminService.setUserActiveStatus(
        userId: user['id'].toString(),
        isActive: newStatus,
      );

      await loadUsers();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus
                ? 'User account restored.'
                : 'User account disabled.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update user: $e',
          ),
        ),
      );
    }
  }

  String formatDate(String? date) {
    if (date == null) return 'Unknown';

    final parsedDate = DateTime.tryParse(date);

    if (parsedDate == null) {
      return 'Unknown';
    }

    return '${parsedDate.month}/${parsedDate.day}/${parsedDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : users.isEmpty
              ? const Center(
                  child: Text(
                    'No users found.',
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadUsers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user =
                          users[index];

                      final String name =
                          user['full_name'] ??
                              'No name';

                      final String role =
                          user['role'] == 'seller'
                              ? 'Seller'
                              : 'Customer';

                      final String email =
                          user['email'] ??
                              'No email';

                      final String phone =
                          user['phone'] ??
                              'No phone number';

                      final bool isActive =
                          user['is_active'] ??
                              true;

                      return Card(
                        margin:
                            const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: Padding(
                          padding:
                              const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Row(
                                children: [
                                  const CircleAvatar(
                                    child: Icon(
                                      Icons.person,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 12,
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          role,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: role == 'Seller'
                                                ? Colors.blue
                                                : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    isActive
                                        ? 'Active'
                                        : 'Disabled',
                                    style:
                                        TextStyle(
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                      color: isActive
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 12,
                              ),

                              Text(
                                'Email: $email',
                              ),

                              const SizedBox(
                                height: 4,
                              ),

                              Text(
                                'Phone: $phone',
                              ),

                              const SizedBox(
                                height: 4,
                              ),

                              Text(
                                'Joined: ${formatDate(user['created_at']?.toString())}',
                              ),

                              const SizedBox(
                                height: 12,
                              ),

                              Align(
                                alignment:
                                    Alignment.centerRight,
                                child:
                                    OutlinedButton.icon(
                                  onPressed: () =>
                                      changeUserStatus(
                                    user,
                                  ),
                                  icon: Icon(
                                    isActive
                                        ? Icons
                                            .block
                                        : Icons
                                            .restore,
                                  ),
                                  label: Text(
                                    isActive
                                        ? 'Disable'
                                        : 'Restore',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
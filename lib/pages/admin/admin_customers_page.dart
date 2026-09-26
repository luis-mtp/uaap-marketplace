import 'package:flutter/material.dart';
import 'package:uaap_market/services/admin_service.dart';

class AdminCustomersPage extends StatefulWidget {
  const AdminCustomersPage({super.key});

  @override
  State<AdminCustomersPage> createState() => _AdminCustomersPageState();
}

class _AdminCustomersPageState extends State<AdminCustomersPage> {
  final AdminService adminService = AdminService();

  List<Map<String, dynamic>> customers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    try {
      final data =
          await adminService.getAllCustomers();

      if (!mounted) return;

      setState(() {
        customers = data;
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
            'Failed to load customers: $e',
          ),
        ),
      );
    }
  }

  Future<void> changeCustomerStatus(
    Map<String, dynamic> customer,
  ) async {
    final bool currentStatus =
        customer['is_active'] ?? true;

    final bool newStatus = !currentStatus;

    try {
      await adminService.setCustomerActiveStatus(
        userId: customer['id'].toString(),
        isActive: newStatus,
      );

      await loadCustomers();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus
                ? 'Customer account restored.'
                : 'Customer account disabled.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update customer: $e',
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
        title: const Text('Customers'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : customers.isEmpty
              ? const Center(
                  child: Text(
                    'No customers found.',
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadCustomers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer =
                          customers[index];

                      final String name =
                          customer['full_name'] ??
                              'No name';

                      final String email =
                          customer['email'] ??
                              'No email';

                      final String phone =
                          customer['phone'] ??
                              'No phone number';

                      final bool isActive =
                          customer['is_active'] ??
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
                                    child: Text(
                                      name,
                                      style:
                                          const TextStyle(
                                        fontSize: 18,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
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
                                'Joined: ${formatDate(customer['created_at']?.toString())}',
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
                                      changeCustomerStatus(
                                    customer,
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
import 'package:flutter/material.dart';
import 'package:uaap_market/services/admin/admin_service.dart';

class AdminSellerApplicationsPage
    extends StatefulWidget {
  const AdminSellerApplicationsPage({
    super.key,
  });

  @override
  State<AdminSellerApplicationsPage> createState() => _AdminSellerApplicationsPageState();
}

class _AdminSellerApplicationsPageState extends State<AdminSellerApplicationsPage> {
  final AdminService adminService = AdminService();

  List<Map<String, dynamic>> applications = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadApplications();
  }

  Future<void> loadApplications() async {
    try {
      final data =
          await adminService.getSellerApplications();

      if (!mounted) return;

      setState(() {
        applications = data;
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
            'Failed to load seller applications: $e',
          ),
        ),
      );
    }
  }

  Future<void> approveApplication(
    Map<String, dynamic> application,
  ) async {
    try {
      await adminService.setSellerApplicationStatus(
        applicationId:
            application['id'].toString(),
        status: 'approved',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Seller application approved.',
          ),
        ),
      );

      await loadApplications();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to approve application: $e',
          ),
        ),
      );
    }
  }

  Future<void> denyApplication(
    Map<String, dynamic> application,
  ) async {
    final controller = TextEditingController();

    try {
      final reason = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text(
              'Deny Seller Application',
            ),
            content: TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'Enter the reason for denial',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Cancel'),
              ),

              ElevatedButton(
                onPressed: () {
                  final enteredReason =
                      controller.text.trim();

                  if (enteredReason.isEmpty) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please enter a denial reason.',
                        ),
                      ),
                    );

                    return;
                  }

                  Navigator.pop(
                    dialogContext,
                    enteredReason,
                  );
                },
                child: const Text('Deny'),
              ),
            ],
          );
        },
      );

      // The dialog is completely closed here.

      if (reason == null || reason.isEmpty) {
        return;
      }

      await adminService.setSellerApplicationStatus(
        applicationId: application['id'].toString(),
        status: 'denied',
        adminReason: reason,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Seller application denied.',
          ),
        ),
      );

      await loadApplications();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to deny application: $e',
          ),
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;

      case 'denied':
        return Colors.red;

      case 'pending':
        return Colors.orange;

      default:
        return Colors.grey;
    }
  }

  String formatStatus(String status) {
    if (status.isEmpty) return '';

    return status[0].toUpperCase() +
        status.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Seller Applications',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: loadApplications,
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : applications.isEmpty
                ? ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 180),
                      Center(
                        child: Text(
                          'No seller applications.',
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: applications.length,
                    itemBuilder: (
                      context,
                      index,
                    ) {
                      final application =
                          applications[index];

                      final status =
                          application['status']
                              ?.toString() ??
                          '';

                      final name =
                          application['full_name']
                              ?.toString() ??
                          'Unknown';

                      final email =
                          application['email']
                              ?.toString() ??
                          '';

                      final phone =
                          application['phone']
                              ?.toString() ??
                          '';

                      final team =
                          application['team']
                              ?.toString() ??
                          '';

                      final reason =
                          application['reason']
                              ?.toString() ??
                          '';

                      final adminReason =
                          application['admin_reason']
                              ?.toString();

                      return Card(
                        margin:
                            const EdgeInsets.only(
                          bottom: 16,
                        ),
                        child: Padding(
                          padding:
                              const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name,
                                      style:
                                          const TextStyle(
                                        fontSize: 18,
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration:
                                        BoxDecoration(
                                      color:
                                          getStatusColor(
                                        status,
                                      ).withOpacity(
                                        0.12,
                                      ),
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        12,
                                      ),
                                    ),
                                    child: Text(
                                      formatStatus(
                                        status,
                                      ),
                                      style:
                                          TextStyle(
                                        color:
                                            getStatusColor(
                                          status,
                                        ),
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
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

                              if (phone.isNotEmpty)
                                Text(
                                  'Phone: $phone',
                                ),

                              const SizedBox(
                                height: 12,
                              ),

                              Text(
                                'Team: $team',
                                style:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              const Text(
                                'Reason:',
                                style:
                                    TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              const SizedBox(
                                height: 4,
                              ),

                              Text(reason),

                              if (status ==
                                      'denied' &&
                                  adminReason !=
                                      null &&
                                  adminReason
                                      .isNotEmpty) ...[
                                const SizedBox(
                                  height: 12,
                                ),
                                const Text(
                                  'Admin Reason:',
                                  style:
                                      TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                                const SizedBox(
                                  height: 4,
                                ),
                                Text(adminReason),
                              ],

                              if (status ==
                                  'pending') ...[
                                const SizedBox(
                                  height: 16,
                                ),

                                Row(
                                  children: [
                                    Expanded(
                                      child:
                                          ElevatedButton(
                                        onPressed: () =>
                                            approveApplication(
                                          application,
                                        ),
                                        child:
                                            const Text(
                                          'Approve',
                                        ),
                                      ),
                                    ),

                                    const SizedBox(
                                      width: 12,
                                    ),

                                    Expanded(
                                      child:
                                          OutlinedButton(
                                        onPressed: () =>
                                            denyApplication(
                                          application,
                                        ),
                                        child:
                                            const Text(
                                          'Deny',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
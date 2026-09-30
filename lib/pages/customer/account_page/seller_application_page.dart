import 'package:flutter/material.dart';
import 'package:uaap_market/services/seller/seller_application_service.dart';


class SellerApplicationPage extends StatefulWidget {
  const SellerApplicationPage({super.key});

  @override
  State<SellerApplicationPage> createState() =>
      _SellerApplicationPageState();
}

class _SellerApplicationPageState extends State<SellerApplicationPage> {
  
  final SellerApplicationService sellerApplicationService = SellerApplicationService();

  final TextEditingController reasonController =
      TextEditingController();

  final List<String> teams = [
    'AdU',
    'AdMU',
    'DLSU',
    'FEU',
    'NU',
    'UE',
    'UP',
    'UST',
  ];

  List<Map<String, dynamic>> applications = [];

  String? selectedTeam;

  bool isLoading = true;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    loadApplications();
  }

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  Future<void> loadApplications() async {
    try {
      final data =
          await sellerApplicationService.getMyApplications();

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
            'Failed to load applications: $e',
          ),
        ),
      );
    }
  }

  Map<String, dynamic>? get pendingApplication {
    for (final application in applications) {
      if (application['status'] == 'pending') {
        return application;
      }
    }

    return null;
  }

  List<String> get approvedTeams {
    return applications
        .where(
          (application) =>
              application['status'] == 'approved',
        )
        .map(
          (application) =>
              application['team'].toString(),
        )
        .toList();
  }

  Future<void> submitApplication() async {
    if (selectedTeam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a team.',
          ),
        ),
      );
      return;
    }

    final reason = reasonController.text.trim();

    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your reason for applying.',
          ),
        ),
      );
      return;
    }

    if (pendingApplication != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You already have a pending application.',
          ),
        ),
      );
      return;
    }

    if (approvedTeams.contains(selectedTeam)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You are already approved for this team.',
          ),
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      await sellerApplicationService.submitApplication(
        team: selectedTeam!,
        reason: reason,
      );

      if (!mounted) return;

      reasonController.clear();

      setState(() {
        selectedTeam = null;
        isSubmitting = false;
      });

      await loadApplications();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Seller application submitted successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to submit application: $e',
          ),
        ),
      );
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
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final pending = pendingApplication;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Seller Application',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: loadApplications,
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Apply to be a Seller',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Choose a UAAP team and explain why you want to sell its merchandise.',
              ),

              const SizedBox(height: 24),

              if (pending != null)
                _buildPendingApplication(pending)
              else
                _buildApplicationForm(),

              const SizedBox(height: 32),

              if (applications.isNotEmpty)
                _buildApplicationHistory(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationForm() {
    final availableTeams = teams
        .where(
          (team) => !approvedTeams.contains(team),
        )
        .toList();

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Team',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          value: selectedTeam,
          decoration: const InputDecoration(
            labelText: 'Select Team',
            border: OutlineInputBorder(),
          ),
          items: availableTeams.map(
            (team) {
              return DropdownMenuItem<String>(
                value: team,
                child: Text(team),
              );
            },
          ).toList(),
          onChanged: isSubmitting
              ? null
              : (value) {
                  setState(() {
                    selectedTeam = value;
                  });
                },
        ),

        const SizedBox(height: 20),

        const Text(
          'Reason',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        TextField(
          controller: reasonController,
          maxLines: 5,
          enabled: !isSubmitting,
          decoration: const InputDecoration(
            hintText:
                'Explain why you want to become a seller...',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed:
                isSubmitting ? null : submitApplication,
            child: isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Apply',
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingApplication(
    Map<String, dynamic> application,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.hourglass_top,
                  color: Colors.orange,
                ),

                const SizedBox(width: 8),

                const Expanded(
                  child: Text(
                    'Application Pending',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              'Team: ${application['team']}',
            ),

            const SizedBox(height: 8),

            Text(
              'Reason: ${application['reason']}',
            ),

            const SizedBox(height: 16),

            const Text(
              'Your application is currently being reviewed by the administrator.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationHistory() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Application History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        ...applications.map(
          (application) {
            final status =
                application['status']?.toString() ?? '';

            final team =
                application['team']?.toString() ?? '';

            final reason =
                application['reason']?.toString() ?? '';

            final adminReason =
                application['admin_reason']
                    ?.toString();

            return Card(
              margin:
                  const EdgeInsets.only(bottom: 12),
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
                            team,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),

                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: getStatusColor(
                              status,
                            ).withOpacity(0.12),
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: Text(
                            formatStatus(status),
                            style: TextStyle(
                              color:
                                  getStatusColor(status),
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Reason: $reason',
                    ),

                    if (status == 'denied' &&
                      adminReason != null &&
                      adminReason.isNotEmpty) ...[
                    const SizedBox(height: 12),

                    const Text(
                      'Admin Reason:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(adminReason),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            selectedTeam =
                                approvedTeams.contains(team)
                                    ? null
                                    : team;

                            reasonController.clear();
                          });

                          if (approvedTeams.contains(team)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'You are already approved for this team.',
                                ),
                              ),
                            );

                            return;
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'You can submit a new application.',
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Apply Again',
                        ),
                      ),
                    ),
                  ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
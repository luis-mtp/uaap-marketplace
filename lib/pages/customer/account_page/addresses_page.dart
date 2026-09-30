import 'package:flutter/material.dart';
import 'package:uaap_market/services/address_service.dart';

class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key});

  @override
  State<AddressesPage> createState() =>
      _AddressesPageState();
}

class _AddressesPageState
    extends State<AddressesPage> {
  final AddressService addressService = AddressService();

  List<Map<String, dynamic>> addresses = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAddresses();
  }

  Future<void> loadAddresses() async {
    try {
      final result =
          await addressService.getAddresses();

      if (!mounted) return;

      setState(() {
        addresses = result;
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
            'Failed to load addresses: $e',
          ),
        ),
      );
    }
  }

  Future<void> showAddressForm({
    Map<String, dynamic>? address,
  }) async {
    final labelController = TextEditingController(
      text: address?['label'] ?? '',
    );

    final fullAddressController = TextEditingController(
      text: address?['full_address'] ?? '',
    );

    final cityController = TextEditingController(
      text: address?['city'] ?? '',
    );

    final provinceController = TextEditingController(
      text: address?['province'] ?? '',
    );

    final postalCodeController = TextEditingController(
      text: address?['postal_code'] ?? '',
    );

    bool isDefault =
        address?['is_default'] ?? false;

    final isEditing = address != null;

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (
              dialogContext,
              setDialogState,
            ) {
              return AlertDialog(
                title: Text(
                  isEditing
                      ? 'Edit Address'
                      : 'Add Address',
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: labelController,
                        decoration: const InputDecoration(
                          labelText: 'Label',
                          hintText: 'e.g. Home, School',
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: fullAddressController,
                        decoration: const InputDecoration(
                          labelText: 'Full Address',
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: cityController,
                        decoration: const InputDecoration(
                          labelText: 'City',
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: provinceController,
                        decoration: const InputDecoration(
                          labelText: 'Province',
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: postalCodeController,
                        keyboardType:
                            TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Postal Code',
                        ),
                      ),

                      const SizedBox(height: 8),

                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Set as default address',
                        ),
                        value: isDefault,
                        onChanged: (value) {
                          setDialogState(() {
                            isDefault =
                                value ?? false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(
                        dialogContext,
                        false,
                      );
                    },
                    child: const Text('Cancel'),
                  ),

                  ElevatedButton(
                    onPressed: () async {
                      if (labelController.text
                              .trim()
                              .isEmpty ||
                          fullAddressController.text
                              .trim()
                              .isEmpty ||
                          cityController.text
                              .trim()
                              .isEmpty ||
                          provinceController.text
                              .trim()
                              .isEmpty ||
                          postalCodeController.text
                              .trim()
                              .isEmpty) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please fill in all fields.',
                            ),
                          ),
                        );

                        return;
                      }

                      try {
                        if (isEditing) {
                          await addressService.updateAddress(
                            addressId: address['id'],
                            label:
                                labelController.text.trim(),
                            fullAddress:
                                fullAddressController.text
                                    .trim(),
                            city:
                                cityController.text.trim(),
                            province:
                                provinceController.text
                                    .trim(),
                            postalCode:
                                postalCodeController.text
                                    .trim(),
                            isDefault: isDefault,
                          );
                        } else {
                          await addressService.addAddress(
                            label:
                                labelController.text.trim(),
                            fullAddress:
                                fullAddressController.text
                                    .trim(),
                            city:
                                cityController.text.trim(),
                            province:
                                provinceController.text
                                    .trim(),
                            postalCode:
                                postalCodeController.text
                                    .trim(),
                            isDefault: isDefault,
                          );
                        }

                        if (!dialogContext.mounted) {
                          return;
                        }

                        Navigator.pop(
                          dialogContext,
                          true,
                        );
                      } catch (e) {
                        if (!dialogContext.mounted) {
                          return;
                        }

                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to save address: $e',
                            ),
                          ),
                        );
                      }
                    },
                    child: Text(
                      isEditing ? 'Save' : 'Add',
                    ),
                  ),
                ],
              );
            },
          );
        },
      );

      // The dialog has completely closed here.
      if (result == true && mounted) {
        await loadAddresses();
      }
    } finally {
      labelController.dispose();
      fullAddressController.dispose();
      cityController.dispose();
      provinceController.dispose();
      postalCodeController.dispose();
    }
  }

  Future<void> deleteAddress(
    String addressId,
  ) async {
    try {
      await addressService.deleteAddress(
        addressId,
      );

      await loadAddresses();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Address deleted.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete address: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Addresses',
        ),
      ),
      floatingActionButton:
          FloatingActionButton(
        onPressed: () async {
          await showAddressForm();
        },
        child: const Icon(
          Icons.add,
        ),
      ),
      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : addresses.isEmpty
              ? RefreshIndicator(
                  onRefresh: loadAddresses,
                  child: ListView(
                    children: const [
                      SizedBox(height: 180),
                      Center(
                        child: Text(
                          'No saved addresses.',
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadAddresses,
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.all(16),
                    itemCount:
                        addresses.length,
                    itemBuilder:
                        (context, index) {
                      final address =
                          addresses[index];

                      final isDefault =
                          address[
                                  'is_default'] ??
                              false;

                      return Card(
                        margin:
                            const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: Padding(
                          padding:
                              const EdgeInsets.all(
                            12,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons
                                        .location_on_outlined,
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  Expanded(
                                    child: Text(
                                      address[
                                              'label'] ??
                                          'Address',
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ),
                                  if (isDefault)
                                    const Chip(
                                      label: Text(
                                        'Default',
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              Text(
                                address[
                                        'full_address'] ??
                                    '',
                              ),

                              Text(
                                '${address['city']}, '
                                '${address['province']} '
                                '${address['postal_code']}',
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .end,
                                children: [
                                  TextButton(
                                    onPressed: () async {
                                      await showAddressForm(
                                        address: address,
                                      );
                                    },
                                    child:
                                        const Text(
                                      'Edit',
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      deleteAddress(
                                        address['id'],
                                      );
                                    },
                                    child:
                                        const Text(
                                      'Delete',
                                    ),
                                  ),
                                ],
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
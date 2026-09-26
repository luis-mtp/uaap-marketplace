import 'package:flutter/material.dart';
import 'package:uaap_market/pages/customer/cart_page/order_confirmation_page.dart';
import 'package:uaap_market/pages/customer/cart_page/payment_method_page.dart';
import 'package:uaap_market/services/address_service.dart';

class CheckoutAddressPage extends StatefulWidget {
  final double subtotal;
  final double deliveryFee;
  final double total;
  
  const CheckoutAddressPage({
    super.key,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
  });

  @override
  State<CheckoutAddressPage> createState() =>
      _CheckoutAddressPageState();
}

class _CheckoutAddressPageState
    extends State<CheckoutAddressPage> {
  final AddressService addressService = AddressService();

  List<Map<String, dynamic>> addresses = [];

  String? selectedAddressId;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAddresses();
  }

  Future<void> loadAddresses() async {
    try {
      final data =
          await addressService.getAddresses();

      if (!mounted) return;

      setState(() {
        addresses = data;

        if (addresses.isNotEmpty) {
          final defaultAddress =
              addresses.firstWhere(
            (address) =>
                address['is_default'] == true,
            orElse: () => addresses.first,
          );

          selectedAddressId =
              defaultAddress['id'];
        }

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load addresses: $e',
          ),
        ),
      );
    }
  }

  Future<void> showAddAddressDialog() async {
    final labelController =
        TextEditingController();

    final addressController =
        TextEditingController();

    final cityController =
        TextEditingController();

    final provinceController =
        TextEditingController();

    final postalCodeController =
        TextEditingController();

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Add New Address',
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: labelController,
                    decoration:
                        const InputDecoration(
                      labelText: 'Label',
                      hintText: 'Home',
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Enter an address label.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller:
                        addressController,
                    decoration:
                        const InputDecoration(
                      labelText: 'Full Address',
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Enter your address.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: cityController,
                    decoration:
                        const InputDecoration(
                      labelText: 'City',
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Enter your city.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller:
                        provinceController,
                    decoration:
                        const InputDecoration(
                      labelText: 'Province',
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Enter your province.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller:
                        postalCodeController,
                    keyboardType:
                        TextInputType.number,
                    decoration:
                        const InputDecoration(
                      labelText: 'Postal Code',
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty) {
                        return 'Enter your postal code.';
                      }

                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!
                    .validate()) {
                  return;
                }

                try {
                  await addressService
                      .addAddress(
                    label:
                        labelController.text.trim(),
                    fullAddress:
                        addressController.text.trim(),
                    city:
                        cityController.text.trim(),
                    province:
                        provinceController.text
                            .trim(),
                    postalCode:
                        postalCodeController.text
                            .trim(),
                    isDefault:
                        addresses.isEmpty,
                  );

                  if (!context.mounted) return;

                  Navigator.pop(
                    context,
                    true,
                  );
                } catch (e) {
                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to add address: $e',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    labelController.dispose();
    addressController.dispose();
    cityController.dispose();
    provinceController.dispose();
    postalCodeController.dispose();

    if (result == true) {
      await loadAddresses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Delivery Address',
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: addresses.isEmpty
                        ? const Center(
                            child: Text(
                              'No saved addresses yet.',
                            ),
                          )
                        : ListView.builder(
                            itemCount:
                                addresses.length,
                            itemBuilder:
                                (context, index) {
                              final address =
                                  addresses[index];

                              final id =
                                  address['id']
                                      as String;

                              final isSelected =
                                  selectedAddressId ==
                                      id;

                              return Card(
                                child: RadioListTile<
                                    String>(
                                  value: id,
                                  groupValue:
                                      selectedAddressId,
                                  onChanged:
                                      (value) {
                                    setState(() {
                                      selectedAddressId =
                                          value;
                                    });
                                  },
                                  title: Text(
                                    address[
                                            'label'] ??
                                        'Address',
                                    style:
                                        const TextStyle(
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${address['full_address']}\n'
                                    '${address['city']}, '
                                    '${address['province']} '
                                    '${address['postal_code']}',
                                  ),
                                  secondary:
                                      isSelected
                                          ? const Icon(
                                              Icons
                                                  .check_circle,
                                            )
                                          : null,
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed:
                          showAddAddressDialog,
                      icon: const Icon(
                        Icons.add,
                      ),
                      label: const Text(
                        'Add New Address',
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selectedAddressId == null
                          ? null
                          : () async {
                              final selected =
                                  addresses.firstWhere(
                                (address) =>
                                    address['id'] ==
                                    selectedAddressId,
                              );

                              final selectedPaymentMethod =
                                  await Navigator.push<String>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PaymentMethodPage(
                                    selectedAddress: selected,
                                  ),
                                ),
                              );

                              if (!context.mounted) return;

                              if (selectedPaymentMethod != null) {
                                final checkoutData = {
                                  'address': selected,
                                  'payment_method':
                                      selectedPaymentMethod,
                                };

                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        OrderConfirmationPage(
                                          checkoutData: checkoutData,
                                          subtotal: widget.subtotal,
                                          deliveryFee: widget.deliveryFee,
                                          total: widget.total,
                                    ),
                                  ),
                                );
                              }
                            },
                      child: const Text(
                        'Continue',
                      ),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}
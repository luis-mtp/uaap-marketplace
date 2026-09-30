import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uaap_market/services/seller/seller_product_service.dart';

class SellerEditProductPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const SellerEditProductPage({
    super.key,
    required this.product,
  });

  @override
  State<SellerEditProductPage> createState() =>
      _SellerEditProductPageState();
}

class _SellerEditProductPageState
    extends State<SellerEditProductPage> {
  final SellerProductService productService =
      SellerProductService();

  XFile? selectedImage;
  Uint8List? selectedImageBytes;
  String? selectedImageExtension;

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();

  final sizeControllers = {
    'S': TextEditingController(),
    'M': TextEditingController(),
    'L': TextEditingController(),
    'XL': TextEditingController(),
    'XXL': TextEditingController(),
  };

  List<Map<String, dynamic>> categories = [];
  List<String> approvedTeams = [];

  String? selectedCategoryId;
  String? selectedCategoryName;
  String? selectedTeam;

  String? existingImageUrl;

  bool isLoading = true;
  bool isSaving = false;
  bool isAvailable = true;

  @override
  void initState() {
    super.initState();
    loadProductData();
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();

    for (final controller in sizeControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> loadProductData() async {
    try {
      final results = await Future.wait([
        productService.getCategories(),
        productService.getMyApprovedTeams(),
      ]);

      final loadedCategories =
          results[0] as List<Map<String, dynamic>>;

      final loadedTeams =
          results[1] as List<String>;

      final categoryId =
          widget.product['category_id']?.toString();

      String? categoryName;

      for (final category in loadedCategories) {
        if (category['id'].toString() == categoryId) {
          categoryName =
              category['name']?.toString();
          break;
        }
      }

      final variants =
          widget.product['product_variants']
                  as List<dynamic>? ??
              [];

      final productTeam =
          widget.product['team']?.toString();

      // Make sure the current product team remains
      // selectable even if the application data changes.
      if (productTeam != null &&
          !loadedTeams.contains(productTeam)) {
        loadedTeams.add(productTeam);
      }

      if (!mounted) return;

      setState(() {
        categories = loadedCategories;
        approvedTeams = loadedTeams;

        nameController.text =
            widget.product['name']?.toString() ?? '';

        descriptionController.text =
            widget.product['description']?.toString() ?? '';

        priceController.text =
            widget.product['price']?.toString() ?? '';

        selectedTeam = productTeam;

        selectedCategoryId = categoryId;
        selectedCategoryName = categoryName;

        existingImageUrl =
            widget.product['image_url']?.toString();

        isAvailable =
            widget.product['is_available'] ?? true;

        // Load Top product variants.
        for (final variant in variants) {
          final size =
              variant['size']?.toString();

          final stock =
              variant['stock']?.toString();

          if (size != null &&
              sizeControllers.containsKey(size)) {
            sizeControllers[size]!.text =
                stock ?? '0';
          }
        }

        // Load regular product stock.
        if (variants.isEmpty) {
          final stock =
              widget.product['stock'];

          if (stock != null) {
            sizeControllers['S']!.text =
                stock.toString();
          }
        }

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
            'Failed to load product: $e',
          ),
        ),
      );
    }
  }

  bool get isTopProduct {
    return selectedCategoryName == 'Top';
  }

  Future<void> saveProduct() async {
    final name =
        nameController.text.trim();

    final description =
        descriptionController.text.trim();

    final priceText =
        priceController.text.trim();

    if (name.isEmpty ||
        priceText.isEmpty ||
        selectedTeam == null ||
        selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill in all required fields.',
          ),
        ),
      );

      return;
    }

    final price =
        double.tryParse(priceText);

    if (price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid price.',
          ),
        ),
      );

      return;
    }

    int? stock;

    // Regular product stock.
    if (!isTopProduct) {
      final stockText =
          sizeControllers['S']!.text.trim();

      if (stockText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please enter the product stock.',
            ),
          ),
        );

        return;
      }

      stock = int.tryParse(stockText);

      if (stock == null || stock < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please enter a valid stock quantity.',
            ),
          ),
        );

        return;
      }
    }

    // Top product stock.
    if (isTopProduct) {
      for (final size in sizeControllers.keys) {
        final value =
            sizeControllers[size]!.text.trim();

        if (value.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please enter stock for size $size.',
              ),
            ),
          );

          return;
        }

        final parsed =
            int.tryParse(value);

        if (parsed == null || parsed < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Invalid stock for size $size.',
              ),
            ),
          );

          return;
        }
      }
    }

    setState(() {
      isSaving = true;
    });

    try {
      String imageUrl =
          existingImageUrl ?? '';

      // Upload a replacement image only
      // when the seller selected a new image.
      if (selectedImageBytes != null) {
        imageUrl =
            await productService.uploadProductImage(
          imageBytes: selectedImageBytes!,
          team: selectedTeam!,
          fileExtension:
              selectedImageExtension!,
        );
      }

      final productId =
          widget.product['id'].toString();

      await productService.updateProduct(
        productId: productId,
        name: name,
        description: description,
        price: price,
        team: selectedTeam!,
        categoryId: selectedCategoryId!,
        imageUrl: imageUrl,
        isAvailable: isAvailable,
        stock: stock,
      );

      // Update Top product variants.
      if (isTopProduct) {
        final sizeStocks = <String, int>{};

        for (final entry in sizeControllers.entries) {
          sizeStocks[entry.key] =
              int.parse(entry.value.text.trim());
        }

        await productService.syncProductVariants(
          productId: productId,
          sizeStocks: sizeStocks,
        );
      }  else {
        await productService.deleteProductVariants(productId);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Product updated successfully.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update product: $e',
          ),
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      isSaving = false;
    });
  }

  Future<void> pickProductImage() async {
    final picker = ImagePicker();

    final image =
        await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image == null) {
      return;
    }

    final bytes =
        await image.readAsBytes();

    final fileName = image.name;

    final extension =
        fileName.contains('.')
            ? fileName
                .split('.')
                .last
                .toLowerCase()
            : '';

    if (![
      'png',
      'jpg',
      'jpeg',
    ].contains(extension)) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a PNG, JPG, or JPEG image.',
          ),
        ),
      );

      return;
    }

    setState(() {
      selectedImage = image;
      selectedImageBytes = bytes;
      selectedImageExtension = extension;
    });
  }

  Widget _buildProductImage() {
    // Newly selected image.
    if (selectedImageBytes != null) {
      return ClipRRect(
        borderRadius:
            BorderRadius.circular(12),
        child: Image.memory(
          selectedImageBytes!,
          width: double.infinity,
          height: 220,
          fit: BoxFit.contain,
        ),
      );
    }

    // Existing image.
    if (existingImageUrl != null &&
        existingImageUrl!.isNotEmpty) {
      final imageUrl =
          existingImageUrl!;

      final isNetworkImage =
          imageUrl.startsWith('http://') ||
              imageUrl.startsWith('https://');

      if (isNetworkImage) {
        return ClipRRect(
          borderRadius:
              BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            width: double.infinity,
            height: 220,
            fit: BoxFit.contain,
            errorBuilder:
                (context, error, stackTrace) {
              return _imagePlaceholder();
            },
          ),
        );
      }

      return ClipRRect(
        borderRadius:
            BorderRadius.circular(12),
        child: Image.asset(
          imageUrl,
          width: double.infinity,
          height: 220,
          fit: BoxFit.contain,
          errorBuilder:
              (context, error, stackTrace) {
            return _imagePlaceholder();
          },
        ),
      );
    }

    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey,
        ),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 60,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Image',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        _buildProductImage(),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed:
                pickProductImage,
            icon: const Icon(
              Icons.photo_library_outlined,
            ),
            label: const Text(
              'Change Image',
            ),
          ),
        ),

        const SizedBox(height: 4),

        const Text(
          'Supported formats: PNG, JPG, JPEG',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Edit Product',
          ),
        ),
        body: const Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Product',
        ),
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            TextField(
              controller:
                  nameController,
              decoration:
                  const InputDecoration(
                labelText:
                    'Product Name',
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller:
                  descriptionController,
              maxLines: 3,
              decoration:
                  const InputDecoration(
                labelText:
                    'Description',
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller:
                  priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration:
                  const InputDecoration(
                labelText: 'Price',
                prefixText: '₱ ',
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue:
                  selectedTeam,
              decoration:
                  const InputDecoration(
                labelText: 'Team',
                border:
                    OutlineInputBorder(),
              ),
              items: approvedTeams.map(
                (team) {
                  return DropdownMenuItem<String>(
                    value: team,
                    child: Text(team),
                  );
                },
              ).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedTeam = value;
                });
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue:
                  selectedCategoryId,
              decoration:
                  const InputDecoration(
                labelText: 'Category',
                border:
                    OutlineInputBorder(),
              ),
              items: categories.map(
                (category) {
                  return DropdownMenuItem<String>(
                    value:
                        category['id'].toString(),
                    child: Text(
                      category['name'].toString(),
                    ),
                  );
                },
              ).toList(),
              onChanged: (value) {
                if (value == null) return;

                final selected =
                    categories.firstWhere(
                  (category) =>
                      category['id'].toString() ==
                      value,
                );

                setState(() {
                  selectedCategoryId =
                      value;

                  selectedCategoryName =
                      selected['name'].toString();
                });
              },
            ),

            const SizedBox(height: 16),

            _buildImagePicker(),

            const SizedBox(height: 24),

            Text(
              'Inventory',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontWeight:
                        FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 12),

            if (isTopProduct)
              ...sizeControllers.entries.map(
                (entry) {
                  return Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: TextField(
                      controller:
                          entry.value,
                      keyboardType:
                          TextInputType.number,
                      decoration:
                          InputDecoration(
                        labelText:
                            '${entry.key} Stock',
                        border:
                            const OutlineInputBorder(),
                      ),
                    ),
                  );
                },
              )
            else
              TextField(
                controller:
                    sizeControllers['S'],
                keyboardType:
                    TextInputType.number,
                decoration:
                    const InputDecoration(
                  labelText: 'Stock',
                  border:
                      OutlineInputBorder(),
                ),
              ),

            const SizedBox(height: 16),

            Card(
              child: SwitchListTile(
                title: const Text(
                  'Product Availability',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  isAvailable
                      ? 'Product is visible and available'
                      : 'Product is unavailable',
                ),
                value: isAvailable,
                onChanged: (value) {
                  setState(() {
                    isAvailable = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    isSaving
                        ? null
                        : saveProduct,
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
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
          ],
        ),
      ),
    );
  }
}
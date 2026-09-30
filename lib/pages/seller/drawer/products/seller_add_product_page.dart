import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uaap_market/services/seller/seller_product_service.dart';

class SellerAddProductPage extends StatefulWidget {
  final String? selectedTeam;

  const SellerAddProductPage({
    super.key,
    this.selectedTeam,
  });

  @override
  State<SellerAddProductPage> createState() =>
      _SellerAddProductPageState();
}

class _SellerAddProductPageState
    extends State<SellerAddProductPage> {
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

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    selectedTeam = widget.selectedTeam;

    loadData();
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

  Future<void> loadData() async {
    try {
      final results = await Future.wait([
        productService.getCategories(),
        productService.getMyApprovedTeams(),
      ]);

      final loadedCategories =
          results[0] as List<Map<String, dynamic>>;

      final loadedTeams =
          results[1] as List<String>;

      if (!mounted) return;

      setState(() {
        categories = loadedCategories;
        approvedTeams = loadedTeams;

        // If the selected team was passed in but is not approved,
        // don't allow it to remain selected.
        if (selectedTeam != null &&
            !approvedTeams.contains(selectedTeam)) {
          selectedTeam = null;
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
            'Failed to load product data: $e',
          ),
        ),
      );
    }
  }

  bool get isTopProduct {
    return selectedCategoryName == 'Top';
  }

  Future<void> saveProduct() async {
    final name = nameController.text.trim();
    final description =
        descriptionController.text.trim();
    final priceText = priceController.text.trim();

    if (name.isEmpty ||
        priceText.isEmpty ||
        selectedImageBytes == null ||
        selectedTeam == null ||
        selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill in all required fields and select an image.',
          ),
        ),
      );

      return;
    }

    final price = double.tryParse(priceText);

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

    // Non-Top products use normal stock.
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

    // Top products use size variants.
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

        final parsed = int.tryParse(value);

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
      // Upload image first.
      final imageUrl =
          await productService.uploadProductImage(
        imageBytes: selectedImageBytes!,
        team: selectedTeam!,
        fileExtension: selectedImageExtension!,
      );

      // Create the product.
      final productId =
          await productService.addProductAndGetId(
        name: name,
        description: description,
        price: price,
        team: selectedTeam!,
        categoryId: selectedCategoryId!,
        imageUrl: imageUrl,
        stock: stock,
      );

      // Create variants for Top products.
      if (isTopProduct) {
        final Map<String, int> sizeStocks = {};

        for (final size in sizeControllers.keys) {
          sizeStocks[size] = int.parse(
            sizeControllers[size]!.text.trim(),
          );
        }

        await productService.addProductVariants(
          productId: productId,
          sizeStocks: sizeStocks,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Product added successfully.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to add product: $e',
          ),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });
    }
  }

  Future<void> pickProductImage() async {
    final picker = ImagePicker();

    final image = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image == null) {
      return;
    }

    final bytes = await image.readAsBytes();

    final fileName = image.name;

    final extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';

    if (!['png', 'jpg', 'jpeg'].contains(extension)) {
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

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Image',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        if (selectedImageBytes != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              selectedImageBytes!,
              width: double.infinity,
              height: 220,
              fit: BoxFit.contain,
            ),
          )
        else
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(
                Icons.image_outlined,
                size: 60,
                color: Colors.grey,
              ),
            ),
          ),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isSaving
                ? null
                : pickProductImage,
            icon: const Icon(
              Icons.photo_library_outlined,
            ),
            label: Text(
              selectedImage == null
                  ? 'Choose Image'
                  : 'Change Image',
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
          title: const Text('Add Product'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Price',
                prefixText: '₱ ',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: selectedTeam,
              decoration: const InputDecoration(
                labelText: 'Team',
                border: OutlineInputBorder(),
              ),
              items: approvedTeams.map((team) {
                return DropdownMenuItem<String>(
                  value: team,
                  child: Text(team),
                );
              }).toList(),
              onChanged: isSaving
                  ? null
                  : (value) {
                      setState(() {
                        selectedTeam = value;
                      });
                    },
            ),

            const SizedBox(height: 8),

            if (approvedTeams.isEmpty)
              const Text(
                'You do not have any approved teams yet.',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category['id'].toString(),
                  child: Text(
                    category['name'].toString(),
                  ),
                );
              }).toList(),
              onChanged: isSaving
                  ? null
                  : (value) {
                      final selected =
                          categories.firstWhere(
                        (category) =>
                            category['id'].toString() ==
                            value,
                      );

                      setState(() {
                        selectedCategoryId = value;
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
                    fontWeight: FontWeight.bold,
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
                      controller: entry.value,
                      keyboardType:
                          TextInputType.number,
                      decoration: InputDecoration(
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
                controller: sizeControllers['S'],
                keyboardType:
                    TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stock',
                  border: OutlineInputBorder(),
                ),
              ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    isSaving ||
                            approvedTeams.isEmpty
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
                        'Add Product',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:uaap_market/services/cart_service.dart';
import 'package:uaap_market/services/product_service.dart';

class ProductDetailsPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsPage({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailsPage> createState() =>
      _ProductDetailsPageState();
}

class _ProductDetailsPageState
    extends State<ProductDetailsPage> {
  final ProductService productService = ProductService();

  List<Map<String, dynamic>> variants = [];

  String? selectedSize;

  bool isLoadingVariants = false;

  final CartService cartService = CartService();

  @override
  void initState() {
    super.initState();

    loadVariants();
  }

  Future<void> loadVariants() async {
    final categoryData = widget.product['categories'];

    if (categoryData == null) {
      return;
    }

    final categoryName = categoryData['name'];

    // Only Top products have sizes.
    if (categoryName != 'Top') {
      return;
    }

    setState(() {
      isLoadingVariants = true;
    });

    try {
      final data = await productService.getProductVariants(
        widget.product['id'],
      );

      if (!mounted) return;

      setState(() {
        variants = data;
        isLoadingVariants = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingVariants = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load sizes: $e'),
        ),
      );
    }
  }

  String get categoryName {
    final categoryData = widget.product['categories'];

    if (categoryData == null) {
      return 'Unknown';
    }

    return categoryData['name'] ?? 'Unknown';
  }

  bool get isTopProduct {
    return categoryName == 'Top';
  }

  bool get productAvailable {
    return widget.product['is_available'] ?? false;
  }

  Widget buildSizeSelector() {
    if (!isTopProduct) {
      return const SizedBox.shrink();
    }

    if (isLoadingVariants) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (variants.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'No sizes available.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        const Text(
          'Select Size',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: variants.map((variant) {
            final String size = variant['size'];

            final int stock = variant['stock'] ?? 0;

            final bool available =
                variant['is_available'] == true &&
                stock > 0;

            final bool selected =
                selectedSize == size;

            return ChoiceChip(
              label: Text(
                available
                    ? size
                    : '$size (Out)',
              ),
              selected: selected,
              onSelected: available
                  ? (selected) {
                      setState(() {
                        selectedSize =
                            selected ? size : null;
                      });
                    }
                  : null,
            );
          }).toList(),
        ),

        const SizedBox(height: 8),

        if (selectedSize != null)
          Text(
            'Selected size: $selectedSize',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Future<void> addProductToCart() async {
    if (isTopProduct && selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a size first.',
          ),
        ),
      );

      return;
    }

    try {
      String? variantId;

      if (isTopProduct) {
        final selectedVariant = variants.firstWhere(
          (variant) =>
              variant['size'] == selectedSize,
        );

        variantId = selectedVariant['id'];
      }

      await cartService.addToCart(
        productId: widget.product['id'],
        variantId: variantId,
        quantity: 1,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Product added to cart.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to add product to cart: $e',
          ),
        ),
      );
    }
  }

  Widget buildStockInformation() {
    if (isTopProduct) {
      return const SizedBox.shrink();
    }

    final int stock = widget.product['stock'] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        'Stock: $stock',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) {
    final isNetworkImage =
        imageUrl.startsWith('http://') ||
        imageUrl.startsWith('https://');

    if (isNetworkImage) {
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return _imageErrorWidget();
        },
      );
    }

    return Image.asset(
      imageUrl,
      fit: BoxFit.contain,
      errorBuilder: (
        context,
        error,
        stackTrace,
      ) {
        return _imageErrorWidget();
      },
    );
  }

  Widget _imageErrorWidget() {
    return const Center(
      child: Icon(
        Icons.image_not_supported,
        size: 80,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name =
        widget.product['name'] ?? 'Unnamed Product';

    final String description =
        widget.product['description'] ??
            'No description available.';

    final String team =
        widget.product['team'] ?? 'Unknown';

    final num price =
        widget.product['price'] ?? 0;

    final String? imageUrl =
        widget.product['image_url']?.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 320,
              child: imageUrl != null
                  ? _buildProductImage(imageUrl)
                  : const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 80,
                      ),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    '₱${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Team: $team',
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Category: $categoryName',
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 15,
                    ),
                  ),

                  buildStockInformation(),

                  buildSizeSelector(),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: productAvailable
                        ? addProductToCart
                        : null,
                      child: Text(
                        productAvailable
                            ? 'ADD TO CART'
                            : 'UNAVAILABLE',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
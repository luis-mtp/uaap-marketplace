import 'package:flutter/material.dart';
import 'package:uaap_market/services/seller/seller_product_service.dart';

class SellerDeletedProductsPage extends StatefulWidget {
  const SellerDeletedProductsPage({super.key});

  @override
  State<SellerDeletedProductsPage> createState() =>
      _SellerDeletedProductsPageState();
}

class _SellerDeletedProductsPageState
    extends State<SellerDeletedProductsPage> {
  final SellerProductService productService =
      SellerProductService();

  List<Map<String, dynamic>> deletedProducts = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDeletedProducts();
  }

  Future<void> loadDeletedProducts() async {
    try {
      final data =
          await productService.getMyDeletedProducts();

      if (!mounted) return;

      setState(() {
        deletedProducts = data;
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
            'Failed to load deleted products: $e',
          ),
        ),
      );
    }
  }

  Widget _buildProductImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.image_not_supported_outlined,
        ),
      );
    }

    if (imageUrl.startsWith('http://') ||
        imageUrl.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return Container(
              width: 80,
              height: 80,
              color: Colors.grey[200],
              child: const Icon(
                Icons.broken_image_outlined,
              ),
            );
          },
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        imageUrl,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return Container(
            width: 80,
            height: 80,
            color: Colors.grey[200],
            child: const Icon(
              Icons.broken_image_outlined,
            ),
          );
        },
      ),
    );
  }

  Future<void> restoreProduct(
    Map<String, dynamic> product,
  ) async {
    final productId = product['id']?.toString();

    if (productId == null) return;

    try {
      await productService.restoreProduct(
        productId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Product restored successfully.',
          ),
        ),
      );

      await loadDeletedProducts();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to restore product: $e',
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
          'Deleted Products',
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : deletedProducts.isEmpty
              ? const Center(
                  child: Text(
                    'No deleted products.',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadDeletedProducts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: deletedProducts.length,
                    itemBuilder: (context, index) {
                      final product =
                          deletedProducts[index];

                      final name =
                          product['name']?.toString() ??
                              'Unnamed Product';

                      final team =
                          product['team']?.toString() ??
                              '';

                      final price =
                          (product['price'] as num?)
                                  ?.toDouble() ??
                              0;

                      final imageUrl =
                          product['image_url']?.toString();

                      final category =
                          product['categories']?['name']
                                  ?.toString() ??
                              'Uncategorized';

                      return Card(
                        margin: const EdgeInsets.only(
                          bottom: 12,
                        ),
                        child: Padding(
                          padding:
                              const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              _buildProductImage(
                                imageUrl,
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      name,
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 4,
                                    ),

                                    Text(
                                      '$team • $category',
                                      style: TextStyle(
                                        color:
                                            Colors.grey[600],
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 4,
                                    ),

                                    Row(
                                      children: [
                                        Text(
                                          '₱${price.toStringAsFixed(2)}',
                                          style:
                                              const TextStyle(
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),

                                        const SizedBox(
                                          width: 6,
                                        ),

                                        const Text(
                                          'Deleted',
                                          style:
                                              TextStyle(
                                            color: Colors.red,
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(
                                      height: 6,
                                    ),

                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          restoreProduct(
                                        product,
                                      ),
                                      icon: const Icon(
                                        Icons.restore,
                                      ),
                                      label: const Text(
                                        'Restore',
                                      ),
                                    ),
                                  ],
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
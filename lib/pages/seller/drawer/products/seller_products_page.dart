import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:uaap_market/pages/seller/drawer/products/seller_add_product_page.dart';
import 'package:uaap_market/pages/seller/drawer/products/seller_edit_product_page.dart';
import 'package:uaap_market/services/seller/seller_product_service.dart';

class SellerProductsPage extends StatefulWidget {
  const SellerProductsPage({super.key});

  @override
  State<SellerProductsPage> createState() =>
      _SellerProductsPageState();
}

class _SellerProductsPageState
    extends State<SellerProductsPage> {
  final SellerProductService productService =
      SellerProductService();

  List<Map<String, dynamic>> products = [];

  bool isLoading = true;

  String selectedTeam = 'All Teams';
  String selectedCategory = 'All Categories';

  List<String> approvedTeams = [];

  final List<String> categories = [
    'All Categories',
    'Top',
    'Caps',
    'Bags',
    'Accessories',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final results = await Future.wait([
        productService.getMyProducts(),
        productService.getMyApprovedTeams(),
      ]);

      final loadedProducts =
          results[0] as List<Map<String, dynamic>>;

      final loadedTeams =
          results[1] as List<String>;

      if (!mounted) return;

      setState(() {
        products = loadedProducts;
        approvedTeams = loadedTeams;
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
            'Failed to load products: $e',
          ),
        ),
      );
    }
  }

  Future<void> loadProducts() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data =
          await productService.getMyProducts();

      if (!mounted) return;

      setState(() {
        products = data;
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
            'Failed to load your products: $e',
          ),
        ),
      );
    }
  }

  List<Map<String, dynamic>> get filteredProducts {
    return products.where((product) {
      final team =
          product['team']?.toString() ?? '';

      final categoryData =
          product['categories'];

      String category = '';

      if (categoryData is Map<String, dynamic>) {
        category =
            categoryData['name']?.toString() ?? '';
      }

      final teamMatches =
          selectedTeam == 'All Teams' ||
              team == selectedTeam;

      final categoryMatches =
          selectedCategory == 'All Categories' ||
              category == selectedCategory;

      return teamMatches && categoryMatches;
    }).toList();
  }

  Future<void> openEditProduct(
    Map<String, dynamic> product,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SellerEditProductPage(
          product: product,
        ),
      ),
    );

    if (result == true && mounted) {
      await loadProducts();
    }
  }

  Future<void> deleteProduct(
    Map<String, dynamic> product,
  ) async {
    final productId =
        product['id'].toString();

    try {
      await productService.deleteProduct(
        productId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Product moved to deleted items.',
          ),
        ),
      );

      await loadProducts();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete product: $e',
          ),
        ),
      );
    }
  }

  Future<void> toggleAvailability(
    Map<String, dynamic> product,
  ) async {
    final productId = product['id']?.toString();

    if (productId == null) return;

    final currentAvailability =
        product['is_available'] ?? true;

    final newAvailability = !currentAvailability;

    try {
      await productService.setProductAvailability(
        productId: productId,
        isAvailable: newAvailability,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newAvailability
                ? 'Product is now available.'
                : 'Product is now unavailable.',
          ),
        ),
      );

      await loadProducts();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update availability: $e',
          ),
        ),
      );
    }
  }

  Widget _buildProductImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        width: 80,
        height: 80,
        color: Colors.grey.shade200,
        child: const Icon(
          Icons.image_not_supported,
        ),
      );
    }

    final isNetworkImage =
        imageUrl.startsWith('http://') ||
            imageUrl.startsWith('https://');

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: isNetworkImage
          ? Image.network(
              imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (
                context,
                error,
                stackTrace,
              ) {
                return _imageErrorWidget();
              },
            )
          : Image.asset(
              imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (
                context,
                error,
                stackTrace,
              ) {
                return _imageErrorWidget();
              },
            ),
    );
  }

  Widget _imageErrorWidget() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey.shade200,
      child: const Icon(
        Icons.broken_image,
      ),
    );
  }

  Widget _buildVariantStocks(dynamic variants) {
    if (variants is! List || variants.isEmpty) {
      return const Text(
        'No size variants',
        style: TextStyle(fontSize: 13),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: variants.map<Widget>((variant) {
        final size =
            variant['size']?.toString() ?? '';

        final stock =
            variant['stock'] ?? 0;

        return Chip(
          label: Text('$size: $stock'),
        );
      }).toList(),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        8,
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: selectedTeam,
              decoration: const InputDecoration(
                labelText: 'Team',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: 'All Teams',
                  child: Text('All Teams'),
                ),
                ...approvedTeams.map((team) {
                  return DropdownMenuItem<String>(
                    value: team,
                    child: Text(team),
                  );
                }),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedTeam = value;
                });
              },
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedCategory = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    Map<String, dynamic> product,
  ) {
    final name =
        product['name']?.toString() ?? '';

    final team =
        product['team']?.toString() ?? '';

    final price =
        product['price'] as num? ?? 0;

    final imageUrl =
        product['image_url']?.toString() ?? '';

    final stock = product['stock'];

    final categoryData =
        product['categories'];

    String category = '';

    if (categoryData is Map<String, dynamic>) {
      category =
          categoryData['name']?.toString() ?? '';
    }

    final variants =
        product['product_variants'];

    final isAvailable =
        product['is_available'] ?? true;

    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) {
              openEditProduct(product);
            },
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
          ),

          SlidableAction(
            onPressed: (_) {
              deleteProduct(product);
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.only(
          bottom: 12,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildProductImage(imageUrl),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '$team • $category',
                      style: TextStyle(
                        color:
                            Colors.grey.shade700,
                      ),
                    ),

                    const SizedBox(height: 4),

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

                        const SizedBox(width: 10),

                        Text(
                          isAvailable
                              ? 'Available'
                              : 'Unavailable',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            color: isAvailable
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    if (category == 'Top')
                      _buildVariantStocks(
                        variants,
                      )
                    else
                      Text(
                        'Stock: ${stock ?? 0}',
                        style:
                            const TextStyle(
                          fontSize: 13,
                        ),
                      ),

                    const SizedBox(height: 10),

                    OutlinedButton.icon(
                      onPressed: () {
                        toggleAvailability(
                          product,
                        );
                      },
                      icon: Icon(
                        isAvailable
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      label: Text(
                        isAvailable
                            ? 'Make Unavailable'
                            : 'Make Available',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Products',
        ),
        actions: [
          IconButton(
            onPressed: loadData,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          _buildFilters(),

          const SizedBox(height: 12),

          Expanded(
            child: isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(),
                  )
                : filteredProducts.isEmpty
                    ? const Center(
                        child: Text(
                          'No products found.',
                          style:
                              TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: loadProducts,
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.all(
                            16,
                          ),
                          itemCount:
                              filteredProducts.length,
                          itemBuilder:
                              (context, index) {
                            return _buildProductCard(
                              filteredProducts[index],
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SellerAddProductPage(),
            ),
          );

          if (result == true && mounted) {
            await loadProducts();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Product',
        ),
      ),
    );
  }
}
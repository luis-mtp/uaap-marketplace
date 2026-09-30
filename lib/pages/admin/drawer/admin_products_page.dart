import 'package:flutter/material.dart';
import 'package:uaap_market/pages/admin/drawer/products/admin_add_product_page.dart';
import 'package:uaap_market/pages/admin/drawer/products/admin_edit_product_page.dart';
import 'package:uaap_market/services/admin/admin_products_service.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class AdminProductsPage extends StatefulWidget {
  final String? selectedTeam;

  const AdminProductsPage({
    super.key,
    this.selectedTeam,
  });

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  final AdminProductService productService = AdminProductService();

  List<Map<String, dynamic>> products = [];

  bool isLoading = true;

  String selectedTeam = 'All Teams';
  String selectedCategory = 'All Categories';

  final List<String> teams = [
    'All Teams',
    'AdU',
    'AdMU',
    'DLSU',
    'FEU',
    'NU',
    'UE',
    'UP',
    'UST',
  ];

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

    if (widget.selectedTeam != null) {
      selectedTeam = widget.selectedTeam!;
    }

    loadProducts();
  }

  Future<void> loadProducts() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await productService.getProducts();

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
          content: Text('Failed to load products: $e'),
        ),
      );
    }
  }

  List<Map<String, dynamic>> get filteredProducts {
    return products.where((product) {
      final team = product['team']?.toString() ?? '';

      final categoryData = product['categories'];

      String category = '';

      if (categoryData is Map<String, dynamic>) {
        category = categoryData['name']?.toString() ?? '';
      }

      final teamMatches =
          selectedTeam == 'All Teams' || team == selectedTeam;

      final categoryMatches =
          selectedCategory == 'All Categories' ||
          category == selectedCategory;

      return teamMatches && categoryMatches;
    }).toList();
  }

  String get pageTitle {
    if (widget.selectedTeam != null) {
      return '${widget.selectedTeam} Products';
    }

    return 'Products & Inventory';
  }

  String get addButtonText {
    if (widget.selectedTeam != null) {
      return 'Add ${widget.selectedTeam} Product';
    }

    return 'Add Product';
  }

  Future<void> openAddProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminAddProductPage(
          selectedTeam: widget.selectedTeam,
        ),
      ),
    );

    if (result == true) {
      await loadProducts();
    }
  }

  Widget _buildTeamSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Teams',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            height: 45,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: teams.length,
              separatorBuilder: (context, index) {
                return const SizedBox(width: 8);
              },
              itemBuilder: (context, index) {
                final team = teams[index];

                final isSelected =
                    team == 'All Teams'
                        ? widget.selectedTeam == null
                        : selectedTeam == team;

                return ChoiceChip(
                  label: Text(team),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (!selected) return;

                    if (team == 'All Teams') {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AdminProductsPage(),
                        ),
                      );

                      return;
                    }

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AdminProductsPage(
                          selectedTeam: team,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // MODIFIED:
  // This now supports BOTH Supabase image URLs
  // and your existing local Flutter asset paths.
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

    // Supabase Storage images start with http/https.
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

  // MODIFIED:
  // One reusable widget for image loading errors.
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

  Future<void> openEditProduct(
    Map<String, dynamic> product,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AdminEditProductPage(
          product: product,
        ),
      ),
    );

    if (result == true && mounted) {
      await loadProducts();
    }
  }

  Future<void> toggleProductAvailability(
    Map<String, dynamic> product,
  ) async {
    final productId = product['id'].toString();
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

  Future<void> deleteProduct(
    Map<String, dynamic> product,
  ) async {
    final productId = product['id'].toString();

    try {
      await productService.softDeleteProduct(
        productId: productId,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
        actions: [
          IconButton(
            onPressed: loadProducts,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTeamSelector(),

          const SizedBox(height: 20),

          _buildFilters(),

          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : filteredProducts.isEmpty
                    ? const Center(
                        child: Text(
                          'No products found.',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: loadProducts,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product =
                                filteredProducts[index];

                            return _buildProductCard(product);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openAddProduct,
        icon: const Icon(Icons.add),
        label: Text(addButtonText),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: selectedTeam,
              decoration: const InputDecoration(
                labelText: 'Team',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              items: teams.map((team) {
                return DropdownMenuItem(
                  value: team,
                  child: Text(team),
                );
              }).toList(),
              onChanged: widget.selectedTeam != null
                  ? null
                  : (value) {
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
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              items: categories.map((category) {
                return DropdownMenuItem(
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
    final name = product['name']?.toString() ?? '';
    final team = product['team']?.toString() ?? '';
    final price = product['price'] as num? ?? 0;

    // This value can now be either:
    // assets/merch/team/...
    // OR
    // https://...supabase.co/...
    final imageUrl =
        product['image_url']?.toString() ?? '';

    final stock = product['stock'];

    final categoryData = product['categories'];

    String category = '';

    if (categoryData is Map<String, dynamic>) {
      category =
          categoryData['name']?.toString() ?? '';
    }

    final variants = product['product_variants'];

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
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // MODIFIED:
              // Uses the new image method.
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
                        color: Colors.grey.shade700,
                      ),
                    ),
      
                    const SizedBox(height: 4),
      
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
      
                      children: [
                        Text(
                          '₱${price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
      
                        const SizedBox(width: 10),
      
                        Text(
                          (product['is_available'] ?? true)
                              ? 'Available'
                              : 'Unavailable',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: (product['is_available'] ?? true)
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
      
                    const SizedBox(height: 8),
      
                    if (category == 'Top')
                      _buildVariantStocks(variants)
                    else
                      Text(
                        'Stock: ${stock ?? 0}',
                        style: const TextStyle(
                          fontSize: 13,
                        ),
                      ),
      
                    const SizedBox(height: 10),
      
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      
                      children: [
                        /* OutlinedButton.icon(
                          onPressed: () => openEditProduct(product),
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                        ), 
      
                        const SizedBox(width: 10), */
      
                        OutlinedButton.icon(
                          onPressed: () => toggleProductAvailability(product),
                          icon: Icon(
                            (product['is_available'] ?? true)
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          label: Text(
                            (product['is_available'] ?? true)
                                ? 'Make Unavailable'
                                : 'Make Available',
                          ),
                        ),
      
                        /* const SizedBox(width: 10),
      
                        OutlinedButton.icon(
                          onPressed: () => deleteProduct(product),
                          icon: const Icon(
                            Icons.delete_outline,
                          ),
                          label: const Text(
                            'Delete',
                          ),
                        ), */
                      ],
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

  Widget _buildVariantStocks(dynamic variants) {
    if (variants is! List ||
        variants.isEmpty) {
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
}
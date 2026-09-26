import 'package:flutter/material.dart';
import 'package:uaap_market/pages/customer/customer_home_page.dart';
import 'package:uaap_market/pages/customer/home_page/product_details_page.dart';
import 'package:uaap_market/services/product_service.dart';

class TeamStorePage extends StatefulWidget {
  final TeamInfo team;

  const TeamStorePage({
    super.key,
    required this.team,
  });

  @override
  State<TeamStorePage> createState() => _TeamStorePageState();
}

class _TeamStorePageState extends State<TeamStorePage> {
  final ProductService productService = ProductService();

  final TextEditingController searchController =
      TextEditingController();

  List<Map<String, dynamic>> products = [];

  bool isLoading = true;

  String searchQuery = '';

  final List<String> categoryOrder = [
    'Top',
    'Caps',
    'Bags',
    'Accessories',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadProducts() async {
    try {
      final data = await productService.getProductsByTeam(
        widget.team.code,
      );

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

  List<Map<String, dynamic>> getProductsForCategory(
    String category,
  ) {
    return products.where((product) {
      final categoryData = product['categories'];

      if (categoryData == null) {
        return false;
      }

      final productCategory =
          categoryData['name'] as String?;

      final productName =
          (product['name'] ?? '').toString().toLowerCase();

      final matchesCategory =
          productCategory == category;

      final matchesSearch =
          productName.contains(searchQuery.toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();
  }

  Widget _buildProductImage(String imageUrl) {
    final isNetworkImage =
        imageUrl.startsWith('http://') ||
        imageUrl.startsWith('https://');

    if (isNetworkImage) {
      return Image.network(
        imageUrl,
        width: double.infinity,
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
      width: double.infinity,
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
        size: 50,
      ),
    );
  }

  Widget productCard(Map<String, dynamic> product) {
    final String name = product['name'] ?? 'Unnamed Product';

    final num price = product['price'] ?? 0;

    final String? imageUrl = product['image_url']?.toString();

    final bool isAvailable =
        product['is_available'] ?? false;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductDetailsPage(
              product: product,
            ),),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? _buildProductImage(imageUrl)
                  : const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 50,
                      ),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '₱${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    isAvailable ? 'Available' : 'Unavailable',
                    style: TextStyle(
                      fontSize: 12,
                      color: isAvailable
                          ? Colors.green
                          : Colors.red,
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

  Widget categorySection(String category) {
    final categoryProducts =
        getProductsForCategory(category);

    if (categoryProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          child: Text(
            category.toUpperCase(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 10),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          itemCount: categoryProducts.length,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (context, index) {
            return productCard(
              categoryProducts[index],
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.team.name} Store'),
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadProducts,
              child: ListView(
                children: [
                  const SizedBox(height: 20),

                  Image.asset(
                    widget.team.logo,
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 12),

                  Center(
                    child: Text(
                      widget.team.name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Center(
                    child: Text(
                      '${widget.team.code} Official Store',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    child: TextField(
                      controller: searchController,
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText:
                            'Search ${widget.team.name} products...',
                        prefixIcon:
                            const Icon(Icons.search),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  searchController.clear();

                                  setState(() {
                                    searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  for (final category in categoryOrder)
                    categorySection(category),

                  if (products.isNotEmpty &&
                      categoryOrder.every(
                        (category) =>
                            getProductsForCategory(
                              category,
                            ).isEmpty,
                      ))
                    const Padding(
                      padding: EdgeInsets.all(30),
                      child: Center(
                        child: Text(
                          'No matching products found.',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                  if (products.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(30),
                      child: Center(
                        child: Text(
                          'No products available for this team.',
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}
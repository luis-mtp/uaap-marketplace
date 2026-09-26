import 'package:flutter/material.dart';
import 'package:uaap_market/pages/auth/login_page.dart';
import 'package:uaap_market/pages/customer/customer_account_page.dart';
import 'package:uaap_market/pages/customer/customer_cart_page.dart';
import 'package:uaap_market/pages/customer/home_page/product_details_page.dart';
import 'package:uaap_market/pages/customer/home_page/team_store_page.dart';
import 'package:uaap_market/services/auth_services.dart';
import 'package:uaap_market/services/product_service.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  final AuthService authService = AuthService();

  int selectedIndex = 0;

  final List<Widget> pages = const [
    CustomerHomeContent(),
    CustomerCartPage(),
    CustomerAccountPage(),
  ];

  Future<void> logout() async {
    await authService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UAAP Marketplace'),
        backgroundColor: Colors.white,
        actions: selectedIndex != 2 ? [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ] : [],
      ),

      body: pages[selectedIndex],

      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

class TeamInfo {
  final String code;
  final String name;
  final String logo;

  const TeamInfo({
    required this.code,
    required this.name,
    required this.logo,
  });
}

const List<TeamInfo> teams = [
  TeamInfo(
    code: 'AdU',
    name: 'Adamson',
    logo: 'assets/logo/teams/ADU_logo.png',
  ),
  TeamInfo(
    code: 'AdMU',
    name: 'Ateneo',
    logo: 'assets/logo/teams/ADMU_logo.png',
  ),
  TeamInfo(
    code: 'DLSU',
    name: 'DLSU',
    logo: 'assets/logo/teams/DLSU_logo.png',
  ),
  TeamInfo(
    code: 'FEU',
    name: 'FEU',
    logo: 'assets/logo/teams/FEU_logo.png',
  ),
  TeamInfo(
    code: 'NU',
    name: 'NU',
    logo: 'assets/logo/teams/NU_logo.png',
  ),
  TeamInfo(
    code: 'UE',
    name: 'UE',
    logo: 'assets/logo/teams/UE_logo.png',
  ),
  TeamInfo(
    code: 'UP',
    name: 'UP',
    logo: 'assets/logo/teams/UP_logo.png',
  ),
  TeamInfo(
    code: 'UST',
    name: 'UST',
    logo: 'assets/logo/teams/UST_logo.png',
  ),
];

class CustomerHomeContent extends StatefulWidget {
  const CustomerHomeContent({super.key});

  @override
  State<CustomerHomeContent> createState() =>
      _CustomerHomeContentState();
}

class _CustomerHomeContentState extends State<CustomerHomeContent> {
  final ProductService productService = ProductService();

  bool isLoading = true;

  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> categories = [];

  String? selectedCategory;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final productData = await productService.getProducts();
      final categoryData = await productService.getCategories();

      if (!mounted) return;

      setState(() {
        products = productData;
        categories = categoryData;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load products: $error'),
        ),
      );
    }
  }

  final TextEditingController searchController = TextEditingController();
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredProducts {
    return products.where((product) {
      final categoryData = product['categories'];

      final productCategory =
          categoryData?['name'] as String?;

      final productName =
          (product['name'] ?? '')
              .toString()
              .toLowerCase();

      final matchesCategory =
          selectedCategory == null ||
          productCategory == selectedCategory;

      final matchesSearch =
          productName.contains(
            searchQuery.toLowerCase(),
          );

      return matchesCategory && matchesSearch;
    }).toList();
  }

  Widget teamSelector() {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: teams.length,
        itemBuilder: (context, index) {
          final team = teams[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TeamStorePage(
                    team: team,
                  ),
                ),
              );
            },
            child: Container(
              width: 85,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Container(
                    width: 65,
                    height: 65,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    child: Image.asset(
                      team.logo,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    team.code,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return _imageErrorWidget();
    }

    final isNetworkImage =
        imageUrl.startsWith('http://') ||
        imageUrl.startsWith('https://');

    if (isNetworkImage) {
      return Image.network(
        imageUrl,
        width: double.infinity,
        fit: BoxFit.cover,
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
      fit: BoxFit.cover,
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 5),

          TextField(
            controller: searchController,
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search),
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
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 15),

          const Text(
            'Teams',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          teamSelector(),      

          const SizedBox(height: 12),

          const Text(
            'Categories',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 45,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                categoryButton('All'),

                ...categories.map(
                  (category) => categoryButton(
                    category['name'],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Products',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          if (filteredProducts.isEmpty)
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
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredProducts.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemBuilder: (context, index) {
                final product = filteredProducts[index];

                // Keep your existing product card here.
                return productCard(product);
              },
            ),
        ],
      ),
    );
  }

  Widget categoryButton(String category) {
    final bool isSelected =
        category == 'All'
            ? selectedCategory == null
            : selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            selectedCategory =
                category == 'All' ? null : category;
          });
        },
      ),
    );
  }

  Widget productCard(Map<String, dynamic> product) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailsPage(
                product: product,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildProductImage(
                product['image_url']?.toString() ?? '',
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    '₱${product['price']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    product['team'] ?? '',
                    style: TextStyle(
                      color: Colors.grey[600],
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
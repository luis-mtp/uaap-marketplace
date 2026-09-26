import 'package:flutter/material.dart';
import 'package:uaap_market/pages/customer/cart_page/checkout_address_page.dart';
import 'package:uaap_market/services/cart_service.dart';

class CustomerCartPage extends StatefulWidget {
  const CustomerCartPage({
    super.key,
  });

  @override
  State<CustomerCartPage> createState() =>
      _CustomerCartPageState();
}

class _CustomerCartPageState
    extends State<CustomerCartPage> {
  final CartService cartService = CartService();

  List<Map<String, dynamic>> cartItems = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    loadCart();
  }

  Future<void> loadCart() async {
    try {
      final data = await cartService.getCartItems();

      if (!mounted) return;

      setState(() {
        cartItems = data;
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
            'Failed to load cart: $e',
          ),
        ),
      );
    }
  }

  double get cartTotal {
    double total = 0;

    for (final item in cartItems) {
      final product = item['products'];

      if (product == null) {
        continue;
      }

      final num price = product['price'] ?? 0;
      final int quantity = item['quantity'] ?? 0;

      total += price * quantity;
    }

    return total;
  }

  double get deliveryFee {
    return cartItems.isEmpty ? 0 : 50;
  }

  double get orderTotal {
    return cartTotal + deliveryFee;
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
      ),
    );
  }

  Widget cartItemCard(
    Map<String, dynamic> item,
  ) {
    final product = item['products'];

    if (product == null) {
      return const SizedBox.shrink();
    }

    final String name =
        product['name'] ?? 'Unnamed Product';

    final num price =
        product['price'] ?? 0;

    final String? imageUrl = product['image_url']?.toString();

    final int quantity =
        item['quantity'] ?? 0;

    final variant =
        item['product_variants'];

    final String? size =
        variant?['size'];

    final int availableStock =
        variant != null
            ? (variant['stock'] ?? 0)
            : (product['stock'] ?? 0);

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              height: 90,
              child: imageUrl != null && imageUrl.isNotEmpty
                ? _buildProductImage(imageUrl)
                : const Icon(
                    Icons.image_not_supported,
                  ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 6),

                  if (size != null)
                    Text(
                      'Size: $size',
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),

                  const SizedBox(height: 6),

                  Text(
                    '₱${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      IconButton(
                        onPressed: quantity > 1
                            ? () => decreaseItemQuantity(item)
                            : null,
                        icon: const Icon(
                          Icons.remove,
                        ),
                      ),

                      Text(
                        '$quantity',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      IconButton(
                        onPressed:
                            quantity < availableStock
                                ? () => increaseItemQuantity(
                                      item,
                                      availableStock,
                                    )
                                : null,
                        icon: const Icon(
                          Icons.add,
                        ),
                      ),
                    ],
                  ),

                  TextButton.icon(
                    onPressed: () => removeItem(item['id']),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    label: const Text(
                      'Remove',
                      style: TextStyle(
                        color: Colors.red,
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

  Future<void> increaseItemQuantity(
    Map<String, dynamic> item,
    int availableStock,
  ) async {
    final int currentQuantity =
        item['quantity'] ?? 0;

    try {
      await cartService.increaseQuantity(
        cartItemId: item['id'],
        currentQuantity: currentQuantity,
        availableStock: availableStock,
      );

      await loadCart();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
        ),
      );
    }
  }

  Future<void> decreaseItemQuantity(
    Map<String, dynamic> item,
  ) async {
    final int currentQuantity =
        item['quantity'] ?? 0;

    if (currentQuantity <= 1) {
      return;
    }

    try {
      await cartService.decreaseQuantity(
        cartItemId: item['id'],
        currentQuantity: currentQuantity,
      );

      await loadCart();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to decrease quantity: $e',
          ),
        ),
      );
    }
  }

  Future<void> removeItem(
    String cartItemId,
  ) async {
    try {
      await cartService.removeFromCart(
        cartItemId,
      );

      await loadCart();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Item removed from cart.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to remove item: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (cartItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 70,
            ),

            SizedBox(height: 16),

            Text(
              'Your cart is empty.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 8),

            Text(
              'Add some products to your cart.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadCart,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'My Cart',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          ...cartItems.map(
            (item) => cartItemCard(item),
          ),

          const SizedBox(height: 10),

          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Divider(),

              const Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal'),
                  Text(
                    '₱${cartTotal.toStringAsFixed(2)}',
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Delivery Fee'),
                  Text(
                    '₱${deliveryFee.toStringAsFixed(2)}',
                  ),
                ],
              ),

              const Divider(),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '₱${orderTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: cartItems.isEmpty ? null : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                               CheckoutAddressPage(
                                subtotal: cartTotal,
                                deliveryFee: deliveryFee,
                                total: orderTotal,
                              ),
                        ),
                      );
                    },
                  child: const Text(
                    'Proceed to Checkout',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
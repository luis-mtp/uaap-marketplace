import 'package:supabase_flutter/supabase_flutter.dart';

class CartService {
  final SupabaseClient supabase = Supabase.instance.client;

  // Adding to Cart Function
  Future<void> addToCart({
    required String productId,
    String? variantId,
    required int quantity,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user.');
    }

    final query = supabase
      .from('cart_items')
      .select('id, quantity')
      .eq('user_id', user.id)
      .eq('product_id', productId);

    final existing = variantId == null
      ? await query
          .isFilter('variant_id', null)
          .maybeSingle()
      : await query
          .eq('variant_id', variantId)
          .maybeSingle();

    if (existing != null) {
      final int currentQuantity =
          existing['quantity'] ?? 0;

      await supabase
        .from('cart_items')
        .update({
          'quantity': currentQuantity + quantity,
        })
        .eq('id', existing['id']);

      return;
    }

    await supabase
      .from('cart_items')
      .insert({
        'user_id': user.id,
        'product_id': productId,
        'variant_id': variantId,
        'quantity': quantity,
      });
  }

  // Fetch User's Cart Items
  Future<List<Map<String, dynamic>>> getCartItems() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user.');
    }

    final data = await supabase
        .from('cart_items')
        .select('''
          id,
          product_id,
          variant_id,
          quantity,
          products (
            id,
            name,
            price,
            image_url,
            team,
            is_available
          ),
          product_variants (
            id,
            size,
            stock,
            is_available
          )
        ''')
        .eq('user_id', user.id)
        .order('added_at');

    return List<Map<String, dynamic>>.from(data);
  }

  // Increase Added Product's Quantity
  Future<void> increaseQuantity({
    required String cartItemId,
    required int currentQuantity,
    required int availableStock,
  }) async {
    if (currentQuantity >= availableStock) {
      throw Exception(
        'You cannot add more than the available stock.',
      );
    }

    await supabase
        .from('cart_items')
        .update({
          'quantity': currentQuantity + 1,
        })
        .eq('id', cartItemId);
  }

  // Decrease Added Product Quantity
  Future<void> decreaseQuantity({
    required String cartItemId,
    required int currentQuantity,
  }) async {
    if (currentQuantity <= 1) {
      return;
    }

    await supabase
        .from('cart_items')
        .update({
          'quantity': currentQuantity - 1,
        })
        .eq('id', cartItemId);
  }

  // Remove Added Product from Cart
  Future<void> removeFromCart(
    String cartItemId,
  ) async {
    await supabase
        .from('cart_items')
        .delete()
        .eq('id', cartItemId);
  }
}
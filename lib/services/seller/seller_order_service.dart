import 'package:supabase_flutter/supabase_flutter.dart';

class SellerOrderService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getMyOrders() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user.');
    }

    final data = await supabase
        .from('orders')
        .select('''
          id,
          user_id,
          seller_id,
          status,
          total_amount,
          created_at,
          delivery_name,
          delivery_phone,
          delivery_address,
          delivery_city,
          delivery_province,
          delivery_postal_code,
          order_items (
            id,
            quantity,
            unit_price,
            product_id,
            variant_id,
            products (
              id,
              name,
              image_url,
              team
            ),
            product_variants (
              id,
              size
            )
          ),
          payments (
            method,
            status
          )
        ''')
        .eq('seller_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  // Update Order Status
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user.');
    }

    await supabase.rpc(
      'set_seller_order_status',
      params: {
        'p_order_id': orderId,
        'p_status': status,
      },
    );
  }
}
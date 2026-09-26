import 'package:supabase_flutter/supabase_flutter.dart';

class OrderService {
  final SupabaseClient supabase = Supabase.instance.client;

  // Places User's Order in DB
  Future<String> placeOrder({
    required String deliveryAddress,
    required String deliveryCity,
    required String deliveryProvince,
    required String deliveryPostalCode,
    required String paymentMethod,
    required double totalAmount,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception(
        'No logged-in user.',
      );
    }

    final result = await supabase.rpc(
      'place_order',
      params: {
        'p_delivery_address':
            deliveryAddress,
        'p_delivery_city':
            deliveryCity,
        'p_delivery_province':
            deliveryProvince,
        'p_delivery_postal_code':
            deliveryPostalCode,
        'p_payment_method':
            paymentMethod,
        'p_total_amount':
            totalAmount,
      },
    );

    return result as String;
  }

  // Fetch User's Orders
  Future<List<Map<String, dynamic>>> getMyOrders() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user.');
    }

    final data = await supabase
      .from('orders')
      .select('''
        id,
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
      .eq('user_id', user.id)
      .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }
}
import 'package:supabase_flutter/supabase_flutter.dart';

class SellerService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> getDashboardStats() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user.');
    }

    final result = await supabase.rpc(
      'get_seller_dashboard_stats',
    );

    return Map<String, dynamic>.from(result);
  }

  Future<List<Map<String, dynamic>>> getRecentOrders() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user.');
    }

    final result = await supabase.rpc(
      'get_seller_recent_orders',
    );

    return List<Map<String, dynamic>>.from(result);
  }

  // Get Seller Sales
  Future<Map<String, dynamic>> getSales() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user.');
    }

    final result = await supabase.rpc('get_seller_sales');

    return Map<String, dynamic>.from(result);
  }
}
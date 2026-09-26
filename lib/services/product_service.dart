import 'package:supabase_flutter/supabase_flutter.dart';

class ProductService {
  final SupabaseClient supabase = Supabase.instance.client;

  // Fetches Products
  Future<List<Map<String, dynamic>>> getProducts() async {
    final data = await supabase
        .from('products')
        .select('''
          id,
          name,
          description,
          price,
          team,
          image_url,
          stock,
          is_available,
          category_id,
          categories (
            id,
            name
          )
        ''')
        .eq('is_available', true)
        .eq('is_deleted', false)
        .order('created_at');

    return List<Map<String, dynamic>>.from(data);
  }
  
  // Categories for Products
  Future<List<Map<String, dynamic>>> getCategories() async {
    final data = await supabase
        .from('categories')
        .select('id, name')
        .order('name');

    return List<Map<String, dynamic>>.from(data);
  }

  // Fetches Products' Size Variants with their Stocks
  Future<List<Map<String, dynamic>>> getProductVariants(
    String productId,
  ) async {
    final data = await supabase
        .from('product_variants')
        .select('id, size, stock, is_available')
        .eq('product_id', productId)
        .order('size');

    return List<Map<String, dynamic>>.from(data);
  }

  // Fetches Products of a Team
  Future<List<Map<String, dynamic>>> getProductsByTeam(
    String team,
  ) async {
    final data = await supabase
        .from('products')
        .select('''
          id,
          name,
          description,
          price,
          team,
          image_url,
          stock,
          is_available,
          category_id,
          categories (
            id,
            name
          )
        ''')
        .eq('team', team)
        .eq('is_available', true)
        .eq('is_deleted', false)
        .order('created_at');

    return List<Map<String, dynamic>>.from(data);
  }
}
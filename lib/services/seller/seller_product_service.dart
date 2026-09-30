import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class SellerProductService {
  final SupabaseClient supabase = Supabase.instance.client;

  // Get the currently logged-in seller's products
  Future<List<Map<String, dynamic>>> getMyProducts() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user.');
    }

    final data = await supabase
      .from('products')
      .select('''
        id,
        seller_id,
        name,
        description,
        price,
        team,
        image_url,
        stock,
        is_available,
        is_deleted,
        category_id,
        categories (
          id,
          name
        ),
        product_variants (
          id,
          size,
          stock,
          is_available
        )
      ''')
      .eq('seller_id', user.id)
      .eq('is_deleted', false)
      .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  // Add a seller product
  Future<void> addProduct({
    required String name,
    required String description,
    required double price,
    required String team,
    required String categoryId,
    required String? imageUrl,
    required int? stock,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user.');
    }

    await supabase.from('products').insert({
      'seller_id': user.id,
      'name': name,
      'description': description,
      'price': price,
      'team': team,
      'category_id': categoryId,
      'image_url': imageUrl,
      'stock': stock,
      'is_available': true,
      'is_deleted': false,
    });
  }

  // Update a seller's product
  Future<void> updateProduct({
    required String productId,
    required String name,
    required String description,
    required double price,
    required String team,
    required String categoryId,
    required String? imageUrl,
    required bool isAvailable,
    required int? stock,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user.');
    }

    await supabase
        .from('products')
        .update({
          'name': name,
          'description': description,
          'price': price,
          'team': team,
          'category_id': categoryId,
          'image_url': imageUrl,
          'is_available': isAvailable,
          'stock': stock,
        })
        .eq('id', productId)
        .eq('seller_id', user.id);
  }

  // Soft-delete a seller's product
  Future<void> deleteProduct(String productId) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user.');
    }

    await supabase
        .from('products')
        .update({
          'is_deleted': true,
          'is_available': false,
        })
        .eq('id', productId)
        .eq('seller_id', user.id);
  }

  // Fetched Approve Teams to Sell
  Future<List<String>> getMyApprovedTeams() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user.');
    }

    final data = await supabase
        .from('seller_applications')
        .select('team')
        .eq('user_id', user.id)
        .eq('status', 'approved')
        .order('team');

    return data
        .map<String>((item) => item['team'] as String)
        .toList();
  }

  // Fetch Product Categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    final data = await supabase
        .from('categories')
        .select('id, name')
        .order('name');

    return List<Map<String, dynamic>>.from(data);
  }

  // Update Product Image
  Future<String> uploadProductImage({
    required Uint8List imageBytes,
    required String team,
    required String fileExtension,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user.');
    }

    final fileName =
        '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

    final teamFolder = team.toLowerCase();
    final filePath = '$teamFolder/$fileName';

    try {
      await supabase.storage
          .from('merch')
          .uploadBinary(
            filePath,
            imageBytes,
            fileOptions: FileOptions(
              upsert: false,
              contentType: fileExtension == 'png'
                  ? 'image/png'
                  : 'image/jpeg',
            ),
          );

      final publicUrl = supabase.storage
          .from('merch')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('IMAGE UPLOAD ERROR: $e');
      rethrow;
    }
  }

  // Add Product
  Future<String> addProductAndGetId({
    required String name,
    required String description,
    required double price,
    required String team,
    required String categoryId,
    required String? imageUrl,
    required int? stock,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user.');
    }

    final data = await supabase
        .from('products')
        .insert({
          'seller_id': user.id,
          'name': name,
          'description': description,
          'price': price,
          'team': team,
          'category_id': categoryId,
          'image_url': imageUrl,
          'stock': stock,
          'is_available': true,
          'is_deleted': false,
        })
        .select('id')
        .single();

    return data['id'] as String;
  }

  // Add Product's Variant
  Future<void> addProductVariants({
    required String productId,
    required Map<String, int> sizeStocks,
  }) async {
    final variants = sizeStocks.entries.map((entry) {
      return {
        'product_id': productId,
        'size': entry.key,
        'stock': entry.value,
        'is_available': entry.value > 0,
      };
    }).toList();

    if (variants.isEmpty) {
      return;
    }

    await supabase
        .from('product_variants')
        .insert(variants);
  }

  // Update Variant
  Future<void> updateProductVariant({
    required String variantId,
    required int stock,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user.');
    }

    await supabase
        .from('product_variants')
        .update({
          'stock': stock,
          'is_available': stock > 0,
        })
        .eq('id', variantId);
  }

  // Fetch Soft Deleted Products
  Future<List<Map<String, dynamic>>> getMyDeletedProducts() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user.');
    }

    final data = await supabase
        .from('products')
        .select('''
          id,
          seller_id,
          name,
          description,
          price,
          team,
          image_url,
          stock,
          is_available,
          is_deleted,
          category_id,
          categories (
            id,
            name
          ),
          product_variants (
            id,
            size,
            stock,
            is_available
          )
        ''')
        .eq('seller_id', user.id)
        .eq('is_deleted', true)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  // Restore Product
  Future<void> restoreProduct(String productId) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user.');
    }

    await supabase
        .from('products')
        .update({
          'is_deleted': false,
          'is_available': true,
        })
        .eq('id', productId)
        .eq('seller_id', user.id);
  }

  // Set Product Availablility
  Future<void> setProductAvailability({
    required String productId,
    required bool isAvailable,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user.');
    }

    await supabase
        .from('products')
        .update({
          'is_available': isAvailable,
        })
        .eq('id', productId)
        .eq('seller_id', user.id);
  }

  // Convert Top to Non-Top Products
  Future<void> deleteProductVariants(String productId) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user.');
    }

    await supabase
        .from('product_variants')
        .delete()
        .eq('product_id', productId);
  }

  // Sync Product and Variants
  Future<void> syncProductVariants({
    required String productId,
    required Map<String, int> sizeStocks,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user.');
    }

    // Get existing variants for this product.
    final existingData = await supabase
        .from('product_variants')
        .select('id, size')
        .eq('product_id', productId);

    final existingVariants =
        List<Map<String, dynamic>>.from(existingData);

    final existingBySize = <String, String>{};

    for (final variant in existingVariants) {
      final id = variant['id']?.toString();
      final size = variant['size']?.toString();

      if (id != null && size != null) {
        existingBySize[size] = id;
      }
    }

    // Update existing variants or create missing ones.
    for (final entry in sizeStocks.entries) {
      final size = entry.key;
      final stock = entry.value;

      if (existingBySize.containsKey(size)) {
        await supabase
            .from('product_variants')
            .update({
              'stock': stock,
              'is_available': stock > 0,
            })
            .eq('id', existingBySize[size]!);
      } else {
        await supabase
            .from('product_variants')
            .insert({
              'product_id': productId,
              'size': size,
              'stock': stock,
              'is_available': stock > 0,
            });
      }
    }
  }
}
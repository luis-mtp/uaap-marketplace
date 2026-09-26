import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

class AdminProductService {
  final SupabaseClient supabase = Supabase.instance.client;

  // Fetches All Products
  Future<List<Map<String, dynamic>>> getProducts() async {
    final data = await supabase
        .from('products')
        .select('''
          id,
          name,
          description,
          price,
          team,
          category_id,
          image_url,
          stock,
          is_available,
          categories (
            name
          ),
          product_variants (
            id,
            size,
            stock,
            is_available
          )
        ''')
        .eq('is_deleted', false)
        .order('created_at');

    return List<Map<String, dynamic>>.from(
      data,
    );
  }

  // Adds Product
  Future<String> addProduct({
    required String name,
    required String description,
    required double price,
    required String team,
    required String categoryId,
    required String imageUrl,
    int? stock,
  }) async {
    final product = await supabase
        .from('products')
        .insert({
          'name': name,
          'description': description,
          'price': price,
          'team': team,
          'category_id': categoryId,
          'image_url': imageUrl,
          'stock': stock,
          'is_available': true,
        })
        .select('id')
        .single();

    return product['id'].toString();
  }

  // Adds Sizes of a Product
  Future<void> addProductVariant({
    required String productId,
    required String size,
    required int stock,
  }) async {
    await supabase
        .from('product_variants')
        .insert({
      'product_id': productId,
      'size': size,
      'stock': stock,
      'is_available': stock > 0,
    });
  }

  // Image Attaching
  Future<String> uploadProductImage({
    required Uint8List imageBytes,
    required String team,
    required String fileExtension,
    }) async {
      final extension = fileExtension.toLowerCase();

      final allowedExtensions = [
        'png',
        'jpg',
        'jpeg',
      ];

      if (!allowedExtensions.contains(extension)) {
        throw Exception(
          'Only PNG, JPG, and JPEG images are supported.',
        );
      }

      final teamFolder = team.toLowerCase();

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}.$extension';

      final filePath = '$teamFolder/$fileName';

      String contentType;

      if (extension == 'png') {
        contentType = 'image/png';
      } else {
        contentType = 'image/jpeg';
      }

      await supabase.storage
          .from('merch')
          .uploadBinary(
            filePath,
            imageBytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: false,
            ),
          );

      final publicUrl = supabase.storage
          .from('merch')
          .getPublicUrl(filePath);

      return publicUrl;
    }

  // Update Product
  Future<void> updateProduct({
    required String productId,
    required String name,
    required String description,
    required double price,
    required String team,
    required String categoryId,
    required String imageUrl,
    required bool isAvailable,
    int? stock,
  }) async {
    await supabase
        .from('products')
        .update({
          'name': name,
          'description': description,
          'price': price,
          'team': team,
          'category_id': categoryId,
          'image_url': imageUrl,
          'stock': stock,
          'is_available': isAvailable,
        })
        .eq('id', productId);
  }

  // Update a Product's Variant
  Future<void> updateProductVariant({
    required String variantId,
    required int stock,
  }) async {
    await supabase
        .from('product_variants')
        .update({
          'stock': stock,
          'is_available': stock > 0,
        })
        .eq('id', variantId);
  }

  // Quick Availability Changing of Product
  Future<void> setProductAvailability({
    required String productId,
    required bool isAvailable,
  }) async {
    await supabase
        .from('products')
        .update({
          'is_available': isAvailable,
        })
        .eq('id', productId);
  }

  // Delete a Product
  Future<void> softDeleteProduct({
    required String productId,
  }) async {
    await supabase
        .from('products')
        .update({
          'is_deleted': true,
        })
        .eq('id', productId);
  }
  
  // Restore Deleted Product
  Future<void> restoreProduct({
    required String productId,
  }) async {
    await supabase
        .from('products')
        .update({
          'is_deleted': false,
        })
        .eq('id', productId);
  }

  // Fetch Deleted Products
  Future<List<Map<String, dynamic>>> getDeletedProducts() async {
    final data = await supabase
        .from('products')
        .select('''
          id,
          name,
          description,
          price,
          team,
          category_id,
          image_url,
          stock,
          is_available,
          is_deleted,
          categories (
            name
          ),
          product_variants (
            id,
            size,
            stock,
            is_available
          )
        ''')
        .eq('is_deleted', true)
        .order('created_at');

    return List<Map<String, dynamic>>.from(data);
  }
}
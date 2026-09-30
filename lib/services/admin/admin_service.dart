import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  final SupabaseClient supabase = Supabase.instance.client;

  // Fetches Dashboard Stats for Admin Home Page
  Future<Map<String, dynamic>> getDashboardStats() async {
    final result = await supabase.rpc('get_admin_orders');

    final orders =
        List<Map<String, dynamic>>.from(result);

    double totalSales = 0;
    int totalOrders = 0;
    int pendingOrders = 0;
    int completedOrders = 0;

    for (final order in orders) {
      final status =
          order['status']?.toString() ?? '';

      final amount =
          (order['total_amount'] as num?)
                  ?.toDouble() ??
              0;

      // Cancelled orders are not included
      // in Total Orders.
      if (status != 'cancelled') {
        totalOrders++;
      }

      if (status == 'delivered') {
        totalSales += amount;
        completedOrders++;
      }

      if (status == 'pending') {
        pendingOrders++;
      }
    }

    return {
      'total_sales': totalSales,
      'total_orders': totalOrders,
      'pending_orders': pendingOrders,
      'completed_orders': completedOrders,
    };
  }

  // Fetches Recent Orders
  Future<List<Map<String, dynamic>>> getRecentOrders() async {
    final result = await supabase.rpc(
      'get_admin_orders',
    );

    final orders =
        List<Map<String, dynamic>>.from(result);

    return orders.take(5).map((order) {
      return {
        'id': order['id'],
        'status': order['status'],
        'total_amount': order['total_amount'],
        'created_at': order['created_at'],
      };
    }).toList();
  }

    // Gets Customer Stock and Product Statistics
    Future<Map<String, int>>
      getQuickStatistics() async {
    final products = await supabase
        .from('products')
        .select('id');

    final customers = await supabase
        .rpc('get_admin_customers');

    final productStock = await supabase
        .from('products')
        .select('id, stock');

    final variantStock = await supabase
        .from('product_variants')
        .select('id, stock');

    int lowStockCount = 0;

    // Non-Top products
    for (final product in productStock) {
      final stock = product['stock'];

      if (stock != null && stock <= 5) {
        lowStockCount++;
      }
    }

    // Top product sizes
    for (final variant in variantStock) {
      final stock = variant['stock'];

      if (stock <= 5) {
        lowStockCount++;
      }
    }

    return {
      'products': products.length,
      'customers': customers.length,
      'low_stock': lowStockCount,
    };
  }

  // Fetch Customers' Orders
  Future<List<Map<String, dynamic>>> getAllOrders() async {
    final data = await supabase.rpc(
      'get_admin_orders',
    );

    return List<Map<String, dynamic>>.from(data);
  }

  // Get Order Details
  Future<List<Map<String, dynamic>>> getOrderItems(
    String orderId,
  ) async {
    final data = await supabase
        .from('order_items')
        .select('''
          id,
          order_id,
          product_id,
          variant_id,
          quantity,
          unit_price,
          products (
            name
          ),
          product_variants (
            size
          )
        ''')
        .eq('order_id', orderId);

    return List<Map<String, dynamic>>.from(data);
  }

  // Get Order Payment Details
  Future<Map<String, dynamic>?> getOrderPayment(
    String orderId,
  ) async {
    final data = await supabase
        .from('payments')
        .select('''
          id,
          order_id,
          method,
          status,
          created_at
        ''')
        .eq('order_id', orderId)
        .maybeSingle();

    return data;
  }

  // Update Order Status
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await supabase.rpc(
      'set_admin_order_status',
      params: {
        'p_order_id': orderId,
        'p_status': status,
      },
    );
  }

  // Fetch Customer Accounts
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final data =
        await supabase.rpc('get_admin_customers');

    return List<Map<String, dynamic>>.from(data);
  }

  // Change Customer's Status
  Future<void> setUserActiveStatus({
    required String userId,
    required bool isActive,
  }) async {
    await supabase.rpc(
      'set_admin_customer_status',
      params: {
        'customer_id': userId,
        'new_status': isActive,
      },
    );
  }

  // Get Sales Summary
  Future<Map<String, dynamic>> getSalesSummary() async {
    final result = await supabase.rpc(
      'get_admin_orders',
    );

    final orders =
        List<Map<String, dynamic>>.from(result);

    double totalSales = 0;
    int totalOrders = 0;
    int completedOrders = 0;

    int pendingOrders = 0;
    int confirmedOrders = 0;
    int shippedOrders = 0;
    int deliveredOrders = 0;
    int cancelledOrders = 0;

    for (final order in orders) {
      final status =
          order['status']?.toString() ?? '';

      final amount =
          (order['total_amount'] as num?)
                  ?.toDouble() ??
              0;

      if (status != 'cancelled') {
        totalOrders++;
      }

      switch (status) {
        case 'pending':
          pendingOrders++;
          break;

        case 'confirmed':
          confirmedOrders++;
          break;

        case 'shipped':
          shippedOrders++;
          break;

        case 'delivered':
          deliveredOrders++;
          totalSales += amount;
          completedOrders++;
          break;

        case 'cancelled':
          cancelledOrders++;
          break;
      }
    }

    double averageOrderValue = 0;

    if (completedOrders > 0) {
      averageOrderValue =
          totalSales / completedOrders;
    }

    final orderItems = await supabase
        .from('order_items')
        .select('quantity');

    int totalItemsSold = 0;

    for (final item in orderItems) {
      final quantity =
          (item['quantity'] as num?)
                  ?.toInt() ??
              0;

      totalItemsSold += quantity;
    }

    return {
      'total_sales': totalSales,
      'total_orders': totalOrders,
      'completed_orders': completedOrders,
      'average_order_value': averageOrderValue,
      'total_items_sold': totalItemsSold,

      'pending_orders': pendingOrders,
      'confirmed_orders': confirmedOrders,
      'shipped_orders': shippedOrders,
      'delivered_orders': deliveredOrders,
      'cancelled_orders': cancelledOrders,
    };
  }

  // Get Sales by UAAP Team
  Future<List<Map<String, dynamic>>> getSalesByTeam() async {
    final result = await supabase.rpc(
      'get_admin_sales_by_team',
    );

    return List<Map<String, dynamic>>.from(result);
  }

  // Get Top-Selling Products
  Future<List<Map<String, dynamic>>> getTopSellingProducts() async {
    final result = await supabase.rpc(
      'get_admin_top_selling_products',
    );

    return List<Map<String, dynamic>>.from(result);
  }

  // Fetch Seller Applications
  Future<List<Map<String, dynamic>>> getSellerApplications() async {
    final data =
        await supabase.rpc(
      'get_admin_seller_applications',
    );

    return List<Map<String, dynamic>>.from(data);
  }

  // Change Seller Application's Status
  Future<void> setSellerApplicationStatus({
    required String applicationId,
    required String status,
    String? adminReason,
  }) async {
    await supabase.rpc(
      'set_seller_application_status',
      params: {
        'application_id': applicationId,
        'new_status': status,
        'new_admin_reason': adminReason,
      },
    );
  }
}
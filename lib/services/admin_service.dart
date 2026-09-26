import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> getDashboardStats() async {
    // Get all orders
    final orders = await supabase
        .from('orders')
        .select('id, status, total_amount');

    double totalSales = 0;
    int pendingOrders = 0;
    int completedOrders = 0;

    for (final order in orders) {
      final status =
          order['status']?.toString() ?? '';

      final amount =
          (order['total_amount'] as num?)
                  ?.toDouble() ??
              0;

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
      'total_orders': orders.length,
      'pending_orders': pendingOrders,
      'completed_orders': completedOrders,
    };
  }

  // Fetches Recent Orders
  Future<List<Map<String, dynamic>>> getRecentOrders() async {
      final data = await supabase
          .from('orders')
          .select(
            'id, status, total_amount, created_at',
          )
          .order(
            'created_at',
            ascending: false,
          )
          .limit(5);

      return List<Map<String, dynamic>>.from(
        data,
      );
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
    final data = await supabase
        .from('orders')
        .select('''
          id,
          user_id,
          delivery_name,
          delivery_phone,
          delivery_address,
          delivery_city,
          delivery_province,
          delivery_postal_code,
          status,
          total_amount,
          notes,
          created_at,
          updated_at
        ''')
        .order('created_at', ascending: false);

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
    await supabase
        .from('orders')
        .update({
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', orderId);
  }

  // Fetch Customer Accounts
  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    final data = await supabase
        .rpc('get_admin_customers');

    return List<Map<String, dynamic>>.from(data);
  }

  // Change Customer's Status
  Future<void> setCustomerActiveStatus({
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
    final orders = await supabase
        .from('orders')
        .select('id, status, total_amount');

    double totalSales = 0;
    int completedOrders = 0;

    int pendingOrders = 0;
    int confirmedOrders = 0;
    int packedOrders = 0;
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

      switch (status) {
        case 'pending':
          pendingOrders++;
          break;

        case 'confirmed':
          confirmedOrders++;
          break;

        case 'packed':
          packedOrders++;
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
        .select('quantity, order_id');

    int totalItemsSold = 0;

    for (final item in orderItems) {
      final quantity =
          (item['quantity'] as num?)?.toInt() ?? 0;

      totalItemsSold += quantity;
    }

    return {
      'total_sales': totalSales,
      'total_orders': orders.length,
      'completed_orders': completedOrders,
      'average_order_value': averageOrderValue,
      'total_items_sold': totalItemsSold,

      'pending_orders': pendingOrders,
      'confirmed_orders': confirmedOrders,
      'packed_orders': packedOrders,
      'shipped_orders': shippedOrders,
      'delivered_orders': deliveredOrders,
      'cancelled_orders': cancelledOrders,
    };
  }

  // Get Sales by UAAP Team
  Future<List<Map<String, dynamic>>> getSalesByTeam() async {
    final orderItems = await supabase
        .from('order_items')
        .select('''
          quantity,
          unit_price,
          order_id,
          orders (
            status
          ),
          products (
            team
          )
        ''');

    final Map<String, double> teamSales = {};

    for (final item in orderItems) {
      final order = item['orders'];
      final product = item['products'];

      if (order == null || product == null) {
        continue;
      }

      final status =
          order['status']?.toString() ?? '';

      // Only delivered orders count as sales
      if (status != 'delivered') {
        continue;
      }

      final team =
          product['team']?.toString() ?? 'Unknown';

      final quantity =
          (item['quantity'] as num?)
                  ?.toDouble() ??
              0;

      final unitPrice =
          (item['unit_price'] as num?)
                  ?.toDouble() ??
              0;

      final itemSales =
          quantity * unitPrice;

      teamSales[team] =
          (teamSales[team] ?? 0) + itemSales;
    }

    final result = teamSales.entries.map((entry) {
      return {
        'team': entry.key,
        'sales': entry.value,
      };
    }).toList();

    result.sort(
      (a, b) =>
          (b['sales'] as double)
              .compareTo(a['sales'] as double),
    );

    return result;
  }

  // Get Top-Selling Products
Future<List<Map<String, dynamic>>> getTopSellingProducts() async {
  final orderItems = await supabase
      .from('order_items')
      .select('''
        quantity,
        unit_price,
        order_id,
        orders (
          status
        ),
        products (
          name
        )
      ''');

  final Map<String, Map<String, dynamic>> productSales = {};

  for (final item in orderItems) {
    final order = item['orders'];
    final product = item['products'];

    if (order == null || product == null) {
      continue;
    }

    final status =
        order['status']?.toString() ?? '';

    // Only delivered orders count as sales
    if (status != 'delivered') {
      continue;
    }

    final productName =
        product['name']?.toString() ?? 'Unknown Product';

    final quantity =
        (item['quantity'] as num?)?.toInt() ?? 0;

    final unitPrice =
        (item['unit_price'] as num?)
                ?.toDouble() ??
            0;

    final sales =
        quantity * unitPrice;

    if (!productSales.containsKey(productName)) {
      productSales[productName] = {
        'product': productName,
        'quantity': 0,
        'sales': 0.0,
      };
    }

    productSales[productName]!['quantity'] =
        (productSales[productName]!['quantity'] as int) +
            quantity;

    productSales[productName]!['sales'] =
        (productSales[productName]!['sales'] as double) +
            sales;
  }

  final result =
      productSales.values.toList();

  result.sort(
    (a, b) =>
        (b['quantity'] as int)
            .compareTo(a['quantity'] as int),
  );

  return result;
}
}
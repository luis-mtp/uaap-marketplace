import 'package:supabase_flutter/supabase_flutter.dart';

class SellerApplicationService {
  final SupabaseClient supabase = Supabase.instance.client;

  /// Submit a new seller application.
  Future<void> submitApplication({
    required String team,
    required String reason,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user.');
    }

    await supabase.from('seller_applications').insert({
      'user_id': user.id,
      'team': team,
      'reason': reason,
    });
  }

  /// Get all seller applications belonging to the
  /// currently logged-in user.
  Future<List<Map<String, dynamic>>> getMyApplications() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user.');
    }

    final data = await supabase
        .from('seller_applications')
        .select('''
          id,
          user_id,
          team,
          reason,
          status,
          admin_reason,
          created_at,
          updated_at
        ''')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  /// Get the currently pending application, if one exists.
  Future<Map<String, dynamic>?> getPendingApplication() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user.');
    }

    final data = await supabase
        .from('seller_applications')
        .select('''
          id,
          user_id,
          team,
          reason,
          status,
          admin_reason,
          created_at,
          updated_at
        ''')
        .eq('user_id', user.id)
        .eq('status', 'pending')
        .maybeSingle();

    return data;
  }
}
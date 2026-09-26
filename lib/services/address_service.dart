import 'package:supabase_flutter/supabase_flutter.dart';

class AddressService {
  final SupabaseClient supabase = Supabase.instance.client;

  // Fetch Addresses of a User
  Future<List<Map<String, dynamic>>> getAddresses() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user.');
    }

    final data = await supabase
        .from('addresses')
        .select('''
          id,
          label,
          full_address,
          city,
          province,
          postal_code,
          is_default
        ''')
        .eq('user_id', user.id)
        .order('is_default', ascending: false)
        .order('created_at');

    return List<Map<String, dynamic>>.from(data);
  }

  // Adds a New Address of a User
  Future<void> addAddress({
    required String label,
    required String fullAddress,
    required String city,
    required String province,
    required String postalCode,
    bool isDefault = false,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user.');
    }

    if (isDefault) {
      await supabase
          .from('addresses')
          .update({
            'is_default': false,
          })
          .eq('user_id', user.id);
    }

    await supabase
        .from('addresses')
        .insert({
          'user_id': user.id,
          'label': label,
          'full_address': fullAddress,
          'city': city,
          'province': province,
          'postal_code': postalCode,
          'is_default': isDefault,
        });
  }

  // Updates a User's Address
  Future<void> updateAddress({
    required String addressId,
    required String label,
    required String fullAddress,
    required String city,
    required String province,
    required String postalCode,
    required bool isDefault,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user.');
    }

    if (isDefault) {
      await supabase
          .from('addresses')
          .update({
            'is_default': false,
          })
          .eq('user_id', user.id)
          .neq('id', addressId);
    }

    await supabase
        .from('addresses')
        .update({
          'label': label,
          'full_address': fullAddress,
          'city': city,
          'province': province,
          'postal_code': postalCode,
          'is_default': isDefault,
        })
        .eq('id', addressId)
        .eq('user_id', user.id);
  }

  // Deletes a User's Address
  Future<void> deleteAddress(
    String addressId,
  ) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user.');
    }

    await supabase
        .from('addresses')
        .delete()
        .eq('id', addressId)
        .eq('user_id', user.id);
  }
}
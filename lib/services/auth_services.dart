import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient supabase = Supabase.instance.client;

  // Login
  Future<AuthResponse> login(
    String email,
    String password,
  ) async {
    try {
      final response =
          await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user == null) {
        throw Exception(
          'Incorrect email or password.',
        );
      }

      final profile = await supabase
          .from('users')
          .select('is_active')
          .eq('id', user.id)
          .single();

      final bool isActive =
          profile['is_active'] ?? true;

      if (!isActive) {
        await supabase.auth.signOut();

        throw Exception(
          'Your account has been disabled. '
          'Please contact the administrator.',
        );
      }

      return response;
    } on AuthException catch (e) {
      // Invalid email/password
      if (e.message.toLowerCase().contains(
            'Invalid login credentials',
          )) {
        throw Exception(
          'Incorrect email or password.',
        );
      }

      // Other Supabase authentication errors
      throw Exception(e.message);
    }
  }

  // Register
  Future<AuthResponse> register(
    String email,
    String password,
  ) async {
    return await supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  // Logout
  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  // Check Logged In User
  User? get currentUser {
    return supabase.auth.currentUser;
  }

  // Check Logged In User's Role
  Future<String?> getUserRole() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return null;
    }

    final data = await supabase
        .from('users')
        .select('role')
        .eq('id', user.id)
        .single();

    return data['role'] as String?;
  }

  // Get Logged In User's Info
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return null;
    }

    final data = await supabase
        .from('users')
        .select('id, full_name, email, phone, role, avatar_url')
        .eq('id', user.id)
        .single();

    return data;
  }
  
  // Update User's Profile
  Future<void> updateUserProfile({
    required String fullName,
    required String phone,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user.');
    }

    await supabase
        .from('users')
        .update({
          'full_name': fullName,
          'phone': phone,
        })
        .eq('id', user.id);
  }

  // Change User's Password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user.');
    }

    final email = user.email;

    if (email == null || email.isEmpty) {
      throw Exception(
        'User email could not be found.',
      );
    }

    // Verify the current password.
    await supabase.auth.signInWithPassword(
      email: email,
      password: currentPassword,
    );

    // Update to the new password.
    await supabase.auth.updateUser(
      UserAttributes(
        password: newPassword,
      ),
    );
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<User?> login(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    return response.user;
  }

  Future<User?> loginEmployee({
    required String businessCode,
    required String username,
    required String password,
  }) async {
    final response = await _client.functions.invoke(
      'login-employee',
      body: {
        'business_code': businessCode.trim().toUpperCase(),
        'username': username.trim().toLowerCase(),
        'password': password,
      },
    );

    if (response.status != 200) {
      final data = response.data;
      final message = data is Map
          ? data['error']?.toString()
          : null;

      throw StateError(
        message ?? 'No se pudo iniciar sesión.',
      );
    }

    final data = response.data;

    if (data is! Map ||
        data['access_token'] is! String ||
        data['refresh_token'] is! String) {
      throw StateError('Respuesta de autenticación inválida.');
    }

    final authResponse = await _client.auth.setSession(
      data['refresh_token'] as String,
    );

    if (authResponse.user == null) {
      throw StateError('No se pudo establecer la sesión.');
    }

    return authResponse.user;
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;
}

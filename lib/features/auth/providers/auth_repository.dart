import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final _client = Supabase.instance.client;

  Future<User?> login(String email, String password) async {
    final AuthResponse response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    return response.user;
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;
}

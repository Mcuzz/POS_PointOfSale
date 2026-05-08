import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final _client = Supabase.instance.client;

  // Iniciar sesión con correo y contraseña en Supabase
  Future<User?> login(String email, String password) async {
    try {
      final AuthResponse response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user;
    } catch (e) {
      // Maneja el error de autenticación (ej. credenciales inválidas)
      print('Error al iniciar sesión: $e');
      return null;
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    await _client.auth.signOut();
  }

  // Obtener el usuario actual activo
  User? get currentUser => _client.auth.currentUser;
}
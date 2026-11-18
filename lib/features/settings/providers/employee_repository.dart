import 'package:supabase_flutter/supabase_flutter.dart';

class EmployeeRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> createEmployee({
    required int businessId,
    required String username,
    required String password,
    required String role,
  }) async {
    final session = _client.auth.currentSession;

    if (session == null) {
      throw StateError('Debes iniciar sesión.');
    }

    final response = await _client.functions.invoke(
      'create-employee',
      body: {
        'business_id': businessId,
        'username': username.trim().toLowerCase(),
        'password': password,
        'role': role,
      },
    );

    if (response.status != 201) {
      final data = response.data;

      final message = data is Map
          ? data['error']?.toString()
          : null;

      throw StateError(
        message ?? 'No se pudo crear el empleado.',
      );
    }
  }
}

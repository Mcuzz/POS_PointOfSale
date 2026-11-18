
import 'package:supabase_flutter/supabase_flutter.dart';

class RoleRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String> getCurrentRole() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw StateError('No existe una sesión activa.');
    }

    final response = await _client
        .from('business_members')
        .select('role')
        .eq('user_id', user.id)
        .eq('is_active', true)
        .limit(2);

    if (response.length != 1) {
      throw StateError(
        'No se encontró una membresía activa única.',
      );
    }

    final role = response.first['role'] as String;

    if (!['owner', 'admin', 'cashier'].contains(role)) {
      throw StateError('Rol no autorizado.');
    }

    return role;
  }
}

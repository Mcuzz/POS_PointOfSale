import 'package:supabase_flutter/supabase_flutter.dart';

class BusinessRepository {
  final _client = Supabase.instance.client;

  Future<int> getCurrentBusinessId() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw StateError('No hay una sesión activa.');
    }

    final response = await _client
        .from('business_members')
        .select('business_id')
        .eq('user_id', user.id)
        .eq('is_active', true)
        .limit(2);

    if (response.isEmpty) {
      throw StateError('El usuario no pertenece a un negocio activo.');
    }

    if (response.length > 1) {
      throw StateError(
        'El usuario pertenece a varios negocios. Debe seleccionar uno.',
      );
    }

    return response.first['business_id'] as int;
  }
}
import 'package:punto_venta/features/pos/models/car_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/providers/business_repository.dart';

class SaleRepository {
  final _client = Supabase.instance.client;
  final _businessRepository = BusinessRepository();

Future<void> processSale(
  List<CartItem> cart,
  double total,
  String paymentMethod,
  String? userId,
) async {
  if (cart.isEmpty) {
    throw StateError('No se puede registrar una venta vacía.');
  }

  final businessId = await _businessRepository.getCurrentBusinessId();

  final items = cart.map((item) {
    return {
      'product_id': item.product.id,
      'quantity': item.quantity,
    };
  }).toList();

  try {
    await _client.rpc(
      'process_business_sale',
      params: {
        'p_business_id': businessId,
        'p_payment_method': paymentMethod,
        'p_items': items,
      },
    );
  } on PostgrestException catch (e) {
    throw Exception('No se pudo completar la venta: ${e.message}');
  }
}
}
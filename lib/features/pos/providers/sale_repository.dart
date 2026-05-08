import 'package:punto_venta/features/pos/models/car_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SaleRepository {
  final _client = Supabase.instance.client;

Future<void> processSale(
    List<CartItem> cart, 
    double total, 
    String paymentMethod, 
    String? userId,
  ) async {
    try {
      // 1. Insertar el encabezado de la venta
      final saleResponse = await _client.from('sales').insert({
        'total': total,
        'payment_method': paymentMethod, // Aquí debe coincidir con la base de datos
        'user_id': userId,
      }).select('id').single();

      final saleId = saleResponse['id'];

      // 2. Preparar el detalle de la venta
      final List<Map<String, dynamic>> saleItems = cart.map((item) {
        return {
          'sale_id': saleId,
          'product_id': item.product.id,
          'quantity': item.quantity,
          'unit_price': item.product.price,
        };
      }).toList();

      // 3. Insertar los items de la venta
      await _client.from('sale_items').insert(saleItems);

      // 4. Actualizar/descontar el stock de cada producto
      for (var item in cart) {
        final newStock = item.product.stock - item.quantity;
        await _client
            .from('products')
            .update({'stock': newStock})
            .eq('id', item.product.id!);
      }
    } catch (e) {
      print('Error al procesar la venta: $e');
      throw Exception('No se pudo completar la venta: $e');
    }
  }
}
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class ProductRepository {
  // Obtenemos la instancia de Supabase
  final _client = Supabase.instance.client;

  // 1. REQUERIMIENTO: Registro de Productos
 Future<void> insertProduct(Product product) async {
    final data = product.toMap();
    data.remove('id');

    await _client.from('products').insert(data);
  }

  // 2. Obtener todos los productos
  Future<List<Product>> getAllProducts() async {
    final response = await _client.from('products').select();
    return response.map((json) => Product.fromMap(json)).toList();
  }

  // 3. Búsqueda por nombre o SKU
  Future<List<Product>> searchProducts(String query) async {
    final response = await _client
        .from('products')
        .select()
        .or('name.ilike.%$query%,sku.ilike.%$query%'); // Búsqueda sensible o insensible a mayúsculas
    
    return response.map((json) => Product.fromMap(json)).toList();
  }

  // 4. REQUERIMIENTO: Edición de Atributos
  Future<void> updateProduct(Product product) async {
    await _client.from('products').update(product.toMap()).eq('id', product.id!);
  }

  // 5. REQUERIMIENTO: Control de Stock Rápido
  Future<void> updateStock(int id, int newStock) async {
    await _client.from('products').update({'stock': newStock}).eq('id', id);
  }

  // 6. REQUERIMIENTO: Eliminación de Registros
  Future<void> deleteProduct(int id) async {
    await _client.from('products').delete().eq('id', id);
  }

  // --- GESTIÓN DE CATEGORÍAS ---

  Future<List<String>> getCategories() async {
    final response = await _client.from('categories').select('name');
    return response.map((item) => item['name'] as String).toList();
  }

  Future<void> insertCategory(String name) async {
    await _client.from('categories').upsert({'name': name}, onConflict: 'name');
  }
}
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../../auth/providers/business_repository.dart';

class ProductRepository {
  final _client = Supabase.instance.client;
  final _businessRepository = BusinessRepository();
  Future<void> insertProduct(Product product) async {
  final businessId = await _businessRepository.getCurrentBusinessId();

  final data = product.toMap();
  data.remove('id');
  data['business_id'] = businessId;

  await _client.from('products').insert(data);
}

Future<List<Product>> getAllProducts() async {
  final businessId = await _businessRepository.getCurrentBusinessId();

  final response = await _client
      .from('products')
      .select()
      .eq('business_id', businessId);

  return response.map((json) => Product.fromMap(json)).toList();
}

Future<List<Product>> searchProducts(String query) async {
  final businessId = await _businessRepository.getCurrentBusinessId();

  final response = await _client
      .from('products')
      .select()
      .eq('business_id', businessId)
      .or('name.ilike.%$query%,sku.ilike.%$query%');

  return response.map((json) => Product.fromMap(json)).toList();
}

Future<void> updateProduct(Product product) async {
  final businessId = await _businessRepository.getCurrentBusinessId();

  final data = product.toMap();
  data.remove('business_id');

  await _client
      .from('products')
      .update(data)
      .eq('id', product.id!)
      .eq('business_id', businessId);
}

Future<void> updateStock(int id, int newStock) async {
  final businessId = await _businessRepository.getCurrentBusinessId();

  await _client
      .from('products')
      .update({'stock': newStock})
      .eq('id', id)
      .eq('business_id', businessId);
}

Future<void> deleteProduct(int id) async {
  final businessId = await _businessRepository.getCurrentBusinessId();

  await _client
      .from('products')
      .delete()
      .eq('id', id)
      .eq('business_id', businessId);
}

Future<List<String>> getCategories() async {
  final businessId = await _businessRepository.getCurrentBusinessId();

  final response = await _client
      .from('categories')
      .select('name')
      .eq('business_id', businessId);

  return response.map((item) => item['name'] as String).toList();
}

Future<void> insertCategory(String name) async {
  final businessId = await _businessRepository.getCurrentBusinessId();

  final existing = await _client
      .from('categories')
      .select('id')
      .eq('business_id', businessId)
      .eq('name', name)
      .limit(1);

  if (existing.isNotEmpty) return;

  await _client.from('categories').insert({
    'name': name,
    'business_id': businessId,
  });
}
}
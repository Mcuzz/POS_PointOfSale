import 'package:supabase_flutter/supabase_flutter.dart';

class ReportRepository {
  final _client = Supabase.instance.client;

  // Obtener el resumen general (Total de dinero y cantidad de ventas)
  Future<Map<String, dynamic>> getSalesSummary() async {
    try {
      final response = await _client.from('sales').select('id, total');
      
      double totalRevenue = 0.0;
      int totalTransactions = response.length;

      for (var item in response) {
        totalRevenue += (item['total'] as num).toDouble();
      }

      return {
        'total_transactions': totalTransactions,
        'total_revenue': totalRevenue,
      };
    } catch (e) {
      print('Error al obtener el resumen de ventas: $e');
      return {'total_transactions': 0, 'total_revenue': 0.0};
    }
  }

  // Obtener el ticket promedio
  Future<double> getAverageTicket() async {
    final summary = await getSalesSummary();
    final transactions = summary['total_transactions'] as int? ?? 0;
    final revenue = (summary['total_revenue'] as num?)?.toDouble() ?? 0.0;

    if (transactions == 0) {
      return 0.0;
    }
    return revenue / transactions;
  }

  // Obtener el historial cronológico (Las últimas 50 ventas)
  Future<List<Map<String, dynamic>>> getRecentSales() async {
    try {
      final response = await _client
          .from('sales')
          .select('*')
          .order('created_at', ascending: false)
          .limit(50);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error al obtener las ventas recientes: $e');
      return [];
    }
  }
  // Eliminar una venta por su ID
  Future<void> deleteSale(int saleId) async {
    try {
      await _client
          .from('sales')
          .delete()
          .eq('id', saleId);
    } catch (e) {
      print('Error al eliminar la venta: $e');
      throw Exception('No se pudo eliminar el reporte.');
    }
  }
}
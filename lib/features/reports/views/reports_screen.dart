import 'package:flutter/material.dart';
import '../providers/report_repository.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportRepository _reportRepo = ReportRepository();
  
  bool _isLoading = true;
  double _totalRevenue = 0.0;
  int _totalTransactions = 0;
  List<Map<String, dynamic>> _recentSales = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final summary = await _reportRepo.getSalesSummary();
    final sales = await _reportRepo.getRecentSales();

    setState(() {
      _totalTransactions = summary['total_transactions'] as int;
      _totalRevenue = (summary['total_revenue'] as num).toDouble();
      _recentSales = sales;
      _isLoading = false;
    });
  }

  // Formateador de fecha simple
  String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  // NUEVO: Función para confirmar y eliminar la venta
  Future<void> _confirmDelete(int saleId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Reporte'),
        content: Text('¿Estás seguro de que deseas eliminar la venta #$saleId? Esta acción no se puede deshacer y borrará los artículos relacionados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _reportRepo.deleteSale(saleId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reporte eliminado con éxito'), backgroundColor: Colors.green),
          );
          _loadData(); // Recargar datos para actualizar la tabla y las tarjetas
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al eliminar el reporte'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dashboard y Reportes',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                
                // SECCIÓN SUPERIOR: Tarjetas de Resumen (KPIs)
                Row(
                  children: [
                    Expanded(child: _buildSummaryCard('Ingresos Totales', '\$${_totalRevenue.toStringAsFixed(2)}', Icons.attach_money, Colors.green)),
                    const SizedBox(width: 20),
                    Expanded(child: _buildSummaryCard('Transacciones', '$_totalTransactions', Icons.receipt_long, Colors.blue)),
                    const SizedBox(width: 20),
                    Expanded(child: _buildSummaryCard('Ticket Promedio', '\$${_totalTransactions > 0 ? (_totalRevenue / _totalTransactions).toStringAsFixed(2) : "0.00"}', Icons.analytics, Colors.orange)),
                  ],
                ),
                const SizedBox(height: 30),

                // SECCIÓN INFERIOR: Historial de Ventas
                const Text(
                  'Historial de Ventas Recientes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _recentSales.isEmpty
                        ? const Center(child: Text('No hay ventas registradas aún.'))
                        : SingleChildScrollView(
                            child: DataTable(
                              headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                              columns: const [
                                DataColumn(label: Text('FOLIO')),
                                DataColumn(label: Text('FECHA Y HORA')),
                                DataColumn(label: Text('MÉTODO DE PAGO')),
                                DataColumn(label: Text('TOTAL')),
                                DataColumn(label: Text('CAJERO')),
                                DataColumn(label: Text('ACCIONES')), // NUEVA COLUMNA
                              ],
                              rows: _recentSales.map((sale) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text('#${sale['id'].toString().padLeft(5, '0')}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                    DataCell(Text(_formatDate(sale['created_at']))),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: sale['payment_method'] == 'Efectivo' ? Colors.green.shade100 : Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(sale['payment_method'], style: TextStyle(color: sale['payment_method'] == 'Efectivo' ? Colors.green.shade700 : Colors.blue.shade700)),
                                      ),
                                    ),
                                    DataCell(Text('\$${(sale['total'] as num).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                                    DataCell(Text(sale['user_id'] ?? 'N/A')),
                                    // NUEVA CELDA CON EL BOTÓN DE ELIMINAR
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        tooltip: 'Eliminar Venta',
                                        onPressed: () => _confirmDelete(sale['id']),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  // Widget reutilizable para las tarjetas superiores
  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
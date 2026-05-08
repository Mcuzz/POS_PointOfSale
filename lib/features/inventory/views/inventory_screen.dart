import 'package:flutter/material.dart';
import 'package:punto_venta/features/inventory/widgets/product_form_dialog.dart';
import '../models/product.dart';
import '../providers/product_repository.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final ProductRepository _repository = ProductRepository();
  List<Product> _products = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // Cargar productos desde SQLite
  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    if (_searchQuery.isEmpty) {
      _products = await _repository.getAllProducts();
    } else {
      _products = await _repository.searchProducts(_searchQuery);
    }
    setState(() => _isLoading = false);
  }

  // Modificar stock rápidamente (Botones + y -)
  Future<void> _updateStock(Product product, int change) async {
    final newStock = product.stock + change;
    if (newStock >= 0 && product.id != null) {
      await _repository.updateStock(product.id!, newStock);
      _loadProducts(); // Recargar la tabla
    }
  }

  // Importa el widget arriba: import '../widgets/product_form_dialog.dart';

  Future<void> _showProductForm({Product? product}) async {
    // Abrimos el Dialog y esperamos el resultado
    final result = await showDialog<Product>(
      context: context,
      barrierDismissible: false, // Obliga a usar los botones para cerrar
      builder: (context) => ProductFormDialog(product: product),
    );

    // Si el usuario presionó "Guardar Producto", el result no será null
    if (result != null) {
      if (product == null) {
        // Modo Creación
        await _repository.insertProduct(result);
      } else {
        // Modo Edición
        await _repository.updateProduct(result);
      }
      _loadProducts(); // Refrescamos la tabla
    }
  }

  // Eliminar producto
  Future<void> _deleteProduct(int id) async {
    await _repository.deleteProduct(id);
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: Título y Buscador
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gestión de Productos',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _showProductForm();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar Nuevo Producto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Barra de Búsqueda
            TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o SKU...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                _searchQuery = value;
                _loadProducts();
              },
            ),
            const SizedBox(height: 20),

            // Tabla de Productos
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _products.isEmpty
                    ? const Center(child: Text('No hay productos registrados.'))
                    : SingleChildScrollView(
                        child: DataTable(
                          headingTextStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                          columns: const [
                            DataColumn(label: Text('PRODUCTO')),
                            DataColumn(label: Text('CATEGORÍA')),
                            DataColumn(label: Text('PRECIO')),
                            DataColumn(label: Text('STOCK')),
                            DataColumn(label: Text('ACCIONES')),
                          ],
                          rows: _products.map((product) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'SKU: ${product.sku ?? 'N/A'}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(Text(product.category)),
                                DataCell(
                                  Text('\$${product.price.toStringAsFixed(2)}'),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            _updateStock(product, -1),
                                      ),
                                      Text(
                                        '${product.stock}',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                          color: Colors.green,
                                        ),
                                        onPressed: () =>
                                            _updateStock(product, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () {
                                          _showProductForm(product: product);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () =>
                                            _deleteProduct(product.id!),
                                      ),
                                    ],
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
}

import 'package:flutter/material.dart';
import 'package:punto_venta/features/inventory/widgets/product_form_dialog.dart';

import '../models/product.dart';
import '../providers/product_repository.dart';

class InventoryScreen extends StatefulWidget {
  final bool canEdit;

  const InventoryScreen({super.key, this.canEdit = false});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final ProductRepository _repository = ProductRepository();

  List<Product> _products = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String _searchQuery = '';
  int _loadVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final version = ++_loadVersion;
    final query = _searchQuery;

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final products = query.isEmpty
          ? await _repository.getAllProducts()
          : await _repository.searchProducts(query);

      if (!mounted || version != _loadVersion) return;

      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || version != _loadVersion) return;

      setState(() => _isLoading = false);

      _showMessage('No se pudieron cargar los productos.', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _updateStock(Product product, int change) async {
    if (!widget.canEdit || _isSaving || product.id == null) {
      return;
    }

    final newStock = product.stock + change;

    if (newStock < 0) return;

    setState(() => _isSaving = true);

    try {
      await _repository.updateStock(product.id!, newStock);

      if (!mounted) return;

      await _loadProducts();
    } catch (_) {
      _showMessage('No se pudo actualizar el inventario.', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _showProductForm({Product? product}) async {
    if (!widget.canEdit || _isSaving) return;

    try {
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => ProductFormDialog(
          product: product,
          onSave: (savedProduct) async {
            if (!widget.canEdit) {
              throw StateError('No tienes permisos para modificar productos.');
            }

            if (product == null) {
              await _repository.insertProduct(savedProduct);
            } else {
              await _repository.updateProduct(savedProduct);
            }
          },
        ),
      );

      if (!mounted) return;

      await _loadProducts();
    } catch (_) {
      _showMessage('No se pudo completar la operación.', isError: true);
    }
  }

  Future<void> _deleteProduct(int id) async {
    if (!widget.canEdit || _isSaving) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este producto?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);

    try {
      await _repository.deleteProduct(id);

      if (!mounted) return;

      await _loadProducts();

      _showMessage('Producto eliminado correctamente.');
    } catch (_) {
      _showMessage('No se pudo eliminar el producto.', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canModify = widget.canEdit && !_isSaving;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gestión de Productos',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (widget.canEdit)
                  ElevatedButton.icon(
                    onPressed: canModify ? () => _showProductForm() : null,
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
            const SizedBox(height: 12),

            if (!widget.canEdit)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      size: 18,
                      color: Colors.blueGrey,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Modo de consulta: inventario de solo lectura',
                      style: TextStyle(color: Colors.blueGrey),
                    ),
                  ],
                ),
              ),

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
                _searchQuery = value.trim();
                _loadProducts();
              },
            ),
            const SizedBox(height: 20),

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
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingTextStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                            columns: [
                              const DataColumn(label: Text('PRODUCTO')),
                              const DataColumn(label: Text('CATEGORÍA')),
                              const DataColumn(label: Text('PRECIO')),
                              const DataColumn(label: Text('STOCK')),
                              if (widget.canEdit)
                                const DataColumn(label: Text('ACCIONES')),
                            ],
                            rows: _products.map((product) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                    Text(
                                      '\$${product.price.toStringAsFixed(2)}',
                                    ),
                                  ),
                                  DataCell(
                                    widget.canEdit
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                tooltip: 'Reducir existencias',
                                                icon: const Icon(
                                                  Icons.remove_circle_outline,
                                                  color: Colors.red,
                                                ),
                                                onPressed:
                                                    canModify &&
                                                        product.stock > 0
                                                    ? () => _updateStock(
                                                        product,
                                                        -1,
                                                      )
                                                    : null,
                                              ),
                                              Text('${product.stock}'),
                                              IconButton(
                                                tooltip: 'Aumentar existencias',
                                                icon: const Icon(
                                                  Icons.add_circle_outline,
                                                  color: Colors.green,
                                                ),
                                                onPressed: canModify
                                                    ? () => _updateStock(
                                                        product,
                                                        1,
                                                      )
                                                    : null,
                                              ),
                                            ],
                                          )
                                        : Text('${product.stock}'),
                                  ),
                                  if (widget.canEdit)
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'Editar producto',
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.blue,
                                            ),
                                            onPressed: canModify
                                                ? () => _showProductForm(
                                                    product: product,
                                                  )
                                                : null,
                                          ),
                                          IconButton(
                                            tooltip: 'Eliminar producto',
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed:
                                                canModify && product.id != null
                                                ? () => _deleteProduct(
                                                    product.id!,
                                                  )
                                                : null,
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
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/product.dart';
import '../providers/product_repository.dart';

class ProductFormDialog extends StatefulWidget {
  final Product? product;
  final Future<void> Function(Product product) onSave;

  const ProductFormDialog({super.key, this.product, required this.onSave});

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final ProductRepository _repository = ProductRepository();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _skuController;

  // Variables dinámicas para las categorías
  List<String> _categories = [];
  String? _selectedCategory;
  bool _isLoadingCategories = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _priceController = TextEditingController(
      text: p?.price.toStringAsFixed(2) ?? '',
    );
    _stockController = TextEditingController(text: p?.stock.toString() ?? '');
    _skuController = TextEditingController(text: p?.sku ?? '');

    // Si estamos editando, guardamos la categoría del producto
    if (p != null) _selectedCategory = p.category;

    // Cargamos las categorías desde SQLite
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await _repository.getCategories();
    setState(() {
      _categories = cats;
      // Si estamos creando un producto nuevo, seleccionamos la primera categoría por defecto
      if (_selectedCategory == null && _categories.isNotEmpty) {
        _selectedCategory = _categories.first;
      }
      _isLoadingCategories = false;
    });
  }

  // --- NUEVA FUNCIÓN: Modal para agregar categoría ---
  Future<void> _showAddCategoryDialog() async {
    String newCategory = '';
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva Categoría'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ej. Cervezas Artesanales',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => newCategory = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result == true && newCategory.trim().isNotEmpty) {
      // Guardamos en SQLite
      await _repository.insertCategory(newCategory.trim());
      // Seleccionamos la nueva categoría y recargamos la lista
      _selectedCategory = newCategory.trim();
      await _loadCategories();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _skuController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      return;
    }

    final savedProduct = Product(
      id: widget.product?.id,
      name: _nameController.text.trim(),
      category: _selectedCategory!,
      price: double.parse(_priceController.text.trim()),
      stock: int.parse(_stockController.text.trim()),
      sku: _skuController.text.trim().isEmpty
          ? null
          : _skuController.text.trim(),
      imagePath: widget.product?.imagePath,
    );

    setState(() => _isSaving = true);

    try {
      await widget.onSave(savedProduct);

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo guardar el producto. Verifica tu conexión e inténtalo nuevamente.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return AlertDialog(
      title: Text(
        isEditing ? 'Editar Producto' : 'Nuevo Producto',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: _isLoadingCategories
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Complete los detalles del inventario.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del Producto',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 15),

                      // --- MODIFICADO: Row con Dropdown y Botón de Agregar ---
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _categories.contains(_selectedCategory)
                                  ? _selectedCategory
                                  : null,
                              decoration: const InputDecoration(
                                labelText: 'Categoría',
                                border: OutlineInputBorder(),
                              ),
                              items: _categories
                                  .map(
                                    (cat) => DropdownMenuItem(
                                      value: cat,
                                      child: Text(cat),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _selectedCategory = value),
                              validator: (value) => value == null
                                  ? 'Seleccione una categoría'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Botón para agregar nueva categoría
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.add,
                                color: Colors.blueAccent,
                              ),
                              tooltip: 'Agregar nueva categoría',
                              onPressed: _showAddCategoryDialog,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      // (Mantén los demás campos: Precio, Stock y SKU exactamente igual que en el código anterior)
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Precio (\$)',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Requerido';
                                }

                                final price = double.tryParse(value.trim());

                                if (price == null || !price.isFinite) {
                                  return 'Número inválido';
                                }

                                if (price < 0) {
                                  return 'El precio no puede ser negativo';
                                }

                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: TextFormField(
                              controller: _stockController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Stock Inicial',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Requerido';
                                }

                                final stock = int.tryParse(value.trim());

                                if (stock == null) {
                                  return 'Número inválido';
                                }

                                if (stock < 0) {
                                  return 'El stock no puede ser negativo';
                                }

                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _skuController,
                        decoration: const InputDecoration(
                          labelText: 'Código SKU (Opcional)',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.qr_code_scanner),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveForm,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Guardar Producto',
                  style: TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }
}

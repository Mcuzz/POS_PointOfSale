import 'package:flutter/material.dart';
import 'package:punto_venta/features/pos/models/car_item.dart';
import 'package:punto_venta/features/pos/views/checkout_screen.dart';
import '../../inventory/models/product.dart';
import '../../inventory/providers/product_repository.dart';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({Key? key}) : super(key: key);

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final ProductRepository _productRepo = ProductRepository();
  
  // Listas de datos
  List<Product> _allProducts = []; // Guarda todos los productos originales
  List<Product> _filteredProducts = []; // Los productos que se muestran actualmente
  List<String> _categories = ['Todas']; // 'Todas' es la opción por defecto
  
  String _selectedCategory = 'Todas';
  List<CartItem> _cart = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Cargar productos y categorías al mismo tiempo
  Future<void> _loadData() async {
    final products = await _productRepo.getAllProducts();
    final categories = await _productRepo.getCategories();
    
    setState(() {
      _allProducts = products;
      _filteredProducts = products;
      _categories = ['Todas', ...categories]; // Agregamos 'Todas' al inicio
    });
  }

  // --- NUEVA FUNCIÓN: Lógica de filtrado ---
  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == 'Todas') {
        _filteredProducts = List.from(_allProducts);
      } else {
        _filteredProducts = _allProducts.where((p) => p.category == category).toList();
      }
    });
  }

  void _addToCart(Product product) {
    setState(() {
      final existingIndex = _cart.indexWhere((item) => item.product.id == product.id);
      if (existingIndex >= 0) {
        _cart[existingIndex].quantity++;
      } else {
        _cart.add(CartItem(product: product));
      }
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      if (_cart[index].quantity > 1) {
        _cart[index].quantity--;
      } else {
        _cart.removeAt(index);
      }
    });
  }

  double get _cartTotal {
    return _cart.fold(0, (sum, item) => sum + item.total);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Row(
        children: [
          // SECCIÓN IZQUIERDA: Catálogo y Filtros
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Terminal de Ventas',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  
                  // --- NUEVA SECCIÓN: Barra de Categorías ---
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = _selectedCategory == category;
                        
                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: ChoiceChip(
                            label: Text(
                              category,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: Colors.blueAccent,
                            backgroundColor: Colors.white,
                            onSelected: (bool selected) {
                              if (selected) {
                                _filterByCategory(category);
                              }
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected ? Colors.blueAccent : Colors.grey.shade300,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Cuadrícula de productos (Ahora usa _filteredProducts)
                  Expanded(
                    child: _filteredProducts.isEmpty
                        ? const Center(child: Text('No hay productos en esta categoría.'))
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 15,
                              mainAxisSpacing: 15,
                              childAspectRatio: 1.2,
                            ),
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = _filteredProducts[index];
                              return InkWell(
                                onTap: () => _addToCart(product),
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // Aquí podrías mostrar la imagen real si product.imagePath no es nulo
                                        const Icon(Icons.fastfood, size: 40, color: Colors.blueAccent),
                                        const SizedBox(height: 10),
                                        Text(
                                          product.name,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '\$${product.price.toStringAsFixed(2)}',
                                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),

          // SECCIÓN DERECHA: El Ticket / Carrito
          Container(
            width: 350,
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text('Orden Actual', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Divider(height: 30),
                
                Expanded(
                  child: _cart.isEmpty
                      ? const Center(child: Text('El carrito está vacío', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: _cart.length,
                          itemBuilder: (context, index) {
                            final item = _cart[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('\$${item.product.price.toStringAsFixed(2)} x ${item.quantity}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('\$${item.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                    onPressed: () => _removeFromCart(index),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                
                const Divider(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TOTAL:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('\$${_cartTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _cart.isEmpty ? null : () async {
                   
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CheckoutScreen(cart: _cart, totalToPay: _cartTotal),
                        ),
                      );
                      if (result == true) {
                        setState(() {
                          _cart.clear();
                        });
                      }
                    
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('COBRAR', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
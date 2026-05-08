import '../../inventory/models/product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  // Calcula el subtotal de esta línea (precio x cantidad)
  double get total => product.price * quantity;
}
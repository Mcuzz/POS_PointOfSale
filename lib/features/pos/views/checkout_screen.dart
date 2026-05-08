import 'package:flutter/material.dart';
import 'package:punto_venta/features/pos/models/car_item.dart';
import '../providers/sale_repository.dart'; 

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> cart;
  final double totalToPay;
  final String? loggedUser;

  const CheckoutScreen({
    Key? key,
    required this.cart,
    required this.totalToPay,
    this.loggedUser,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final SaleRepository _saleRepo = SaleRepository();

  String _amountTenderedStr = "0";
  String _paymentMethod = "Efectivo";
  bool _isProcessing = false;

  double get _amountTendered => double.tryParse(_amountTenderedStr) ?? 0.0;
  double get _change => _amountTendered - widget.totalToPay;

  void _onKeypadPressed(String value) {
    setState(() {
      if (value == 'C') {
        _amountTenderedStr = "0";
      } else if (value == 'DEL') {
        if (_amountTenderedStr.length > 1) {
          _amountTenderedStr = _amountTenderedStr.substring(0, _amountTenderedStr.length - 1);
        } else {
          _amountTenderedStr = "0";
        }
      } else {
        if (_amountTenderedStr == "0") {
          _amountTenderedStr = value;
        } else {
          // Límite extendido para permitir montos más grandes sin romper la UI
          if (_amountTenderedStr.length < 10) {
            _amountTenderedStr += value;
          }
        }
      }
    });
  }

  Future<void> _confirmSale() async {
    if (_isProcessing) return;

    if (_paymentMethod == "Efectivo" && _amountTendered < widget.totalToPay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El monto ingresado es menor al total.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await _saleRepo.processSale(
        widget.cart,
        widget.totalToPay,
        _paymentMethod,
        widget.loggedUser ?? 'Cajero',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venta completada con éxito', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.green),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar la venta: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFullyPaid = _change >= 0;
    final changeColor = isFullyPaid ? Colors.green.shade600 : Colors.red.shade600;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), 
      appBar: AppBar(
        title: const Text('Completar Pago', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Row(
        children: [
          // SECCIÓN IZQUIERDA: Teclado y Método de Pago
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  // Selector de Método de Pago
                  Row(
                    children: [
                      Expanded(child: _buildPaymentMethodBtn(Icons.payments_outlined, "Efectivo")),
                      const SizedBox(width: 16),
                      Expanded(child: _buildPaymentMethodBtn(Icons.credit_card_outlined, "Tarjeta")),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Pantalla Digital del Teclado
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('EFECTIVO RECIBIDO', style: TextStyle(color: Colors.white54, fontSize: 14, letterSpacing: 1.2)),
                        const SizedBox(height: 8),
                        // Uso de FittedBox para adaptar números gigantes en el display
                        SizedBox(
                          height: 60, // Forzamos una altura para que crezca adecuadamente
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              '\$${_amountTendered.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'monospace'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // TECLADO NUMÉRICO RESPONSIVO
                  Expanded(
                    child: Column(
                      children: [
                        _buildNumpadRow(['1', '2', '3']),
                        const SizedBox(height: 12),
                        _buildNumpadRow(['4', '5', '6']),
                        const SizedBox(height: 12),
                        _buildNumpadRow(['7', '8', '9']),
                        const SizedBox(height: 12),
                        _buildNumpadRow(['C', '0', 'DEL']),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),

          // SECCIÓN DERECHA: Resumen de Compra
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.only(right: 24, bottom: 24),
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TOTAL A PAGAR', style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w600, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  // FittedBox para el Total
                  SizedBox(
                    height: 70,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '\$${widget.totalToPay.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w900, color: Color(0xFF2563EB)),
                      ),
                    ),
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(thickness: 1.5, color: Color(0xFFF3F4F6)),
                  ),
                  
                  const Text('CAMBIO', style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w600, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  // FittedBox para el Cambio
                  Expanded(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '\$${isFullyPaid ? _change.toStringAsFixed(2) : "0.00"}',
                          style: TextStyle(fontSize: 80, fontWeight: FontWeight.w900, color: changeColor),
                        ),
                      ),
                    ),
                  ),
                  
                  if (!isFullyPaid && _paymentMethod == "Efectivo") ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        'Faltan \$${(_change.abs()).toStringAsFixed(2)} para completar',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Botón Confirmar extra grande
                  SizedBox(
                    width: double.infinity,
                    height: 80,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _confirmSale,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981), 
                        disabledBackgroundColor: Colors.grey.shade300,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'CONFIRMAR VENTA',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildPaymentMethodBtn(IconData icon, String label) {
    final isSelected = _paymentMethod == label;
    return InkWell(
      onTap: () => setState(() {
        _paymentMethod = label;
        if (label == "Tarjeta") _amountTenderedStr = widget.totalToPay.toStringAsFixed(0);
      }),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade300, width: 2),
          boxShadow: isSelected 
              ? [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.black87, size: 32),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
      ),
    );
  }

  // Creador dinámico de filas para el teclado
  Widget _buildNumpadRow(List<String> keys) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch, 
        children: [
          Expanded(child: _getNumpadBtnWidget(keys[0])),
          const SizedBox(width: 12),
          Expanded(child: _getNumpadBtnWidget(keys[1])),
          const SizedBox(width: 12),
          Expanded(child: _getNumpadBtnWidget(keys[2])),
        ],
      ),
    );
  }

  // Identifica si es un botón de borrar, cancelar o un número normal
  Widget _getNumpadBtnWidget(String value) {
    if (value == 'C') {
      return _buildNumpadBtn(value, color: Colors.red.shade50, textColor: Colors.red.shade700);
    } else if (value == 'DEL') {
      return _buildNumpadBtn(value, icon: Icons.backspace_outlined, textColor: Colors.grey.shade700);
    } else {
      return _buildNumpadBtn(value);
    }
  }

  // El botón numérico (Con FittedBox y fuentes grandes)
  Widget _buildNumpadBtn(String value, {IconData? icon, Color? color, Color? textColor}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onKeypadPressed(value),
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.blue.withOpacity(0.1),
        child: Ink(
          decoration: BoxDecoration(
            color: color ?? Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 3))
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0), // Padding interno para que el texto no toque los bordes
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: icon != null
                    ? Icon(icon, size: 48, color: textColor ?? Colors.black87)
                    : Text(value, style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: textColor ?? Colors.black87)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
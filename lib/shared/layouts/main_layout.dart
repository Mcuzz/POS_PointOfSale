import 'package:flutter/material.dart';
import 'package:punto_venta/features/auth/views/login_screen.dart';

// Importamos nuestros módulos (Features)
import '../../features/pos/views/terminal_screen.dart';
import '../../features/inventory/views/inventory_screen.dart';
import '../../features/reports/views/reports_screen.dart';

class MainLayout extends StatefulWidget {
  // 1. AQUÍ DEFINIMOS EL PARÁMETRO QUE CAUSABA EL ERROR
  final String? loggedUser;

  // 2. LO AGREGAMOS AL CONSTRUCTOR
  const MainLayout({Key? key, this.loggedUser}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const TerminalScreen(),
    const InventoryScreen(),
    const ReportsScreen(),
    const Center(
      child: Text(
        'Pantalla de Ajustes\n(Próximamente)',
        textAlign: TextAlign.center,
      ),
    ),
  ];



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Row(
        children: [
          // Menú Lateral (Sidebar)
          Container(
            width: 100,
            decoration: BoxDecoration(
              color: Colors.white,

              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.storefront, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 10),

                // 3. AQUÍ MOSTRAMOS EL NOMBRE DEL USUARIO DEBAJO DEL LOGO
                Text(
                  widget.loggedUser ?? 'Cajero',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 30),

                // Botones de Navegación
                _buildNavButton(Icons.shopping_cart, "Ventas", 0),
                _buildNavButton(Icons.inventory_2, "Productos", 1),
                _buildNavButton(Icons.bar_chart, "Reportes", 2),

                const Spacer(),

                _buildNavButton(Icons.settings, "Ajustes", 3),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        Icon(Icons.logout, color: Colors.redAccent, size: 28),
                        SizedBox(height: 6),
                        Text(
                          'Salir',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenido Principal
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade700 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

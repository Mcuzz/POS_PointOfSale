
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/providers/role_repository.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/pos/views/terminal_screen.dart';
import '../../features/inventory/views/inventory_screen.dart';
import '../../features/reports/views/reports_screen.dart';
import '../../features/settings/views/settings_screen.dart';

class MainLayout extends StatefulWidget {
  final String? loggedUser;

  const MainLayout({super.key, this.loggedUser});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final _roleRepository = RoleRepository();

  late Future<String> _roleFuture;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _roleFuture = _roleRepository.getCurrentRole();
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cerrar la sesión.'),
        ),
      );
      return;
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const LoginScreen(),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _roleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'No fue posible verificar los permisos.',
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _logout,
                    child: const Text('Cerrar sesión'),
                  ),
                ],
              ),
            ),
          );
        }

        final role = snapshot.data!;
        final canManage = role == 'owner' || role == 'admin';

        final screens = <Widget>[
          const TerminalScreen(),
          InventoryScreen(canEdit: canManage),
          if (canManage) const ReportsScreen(),
          if (canManage)
            SettingsScreen(canManageEmployees: role == 'owner'),
        ];

        final navigation = <({IconData icon, String label})>[
          (icon: Icons.shopping_cart, label: 'Ventas'),
          (icon: Icons.inventory_2, label: 'Productos'),
          if (canManage)
            (icon: Icons.bar_chart, label: 'Reportes'),
          if (canManage)
            (icon: Icons.settings, label: 'Ajustes'),
        ];

        final currentIndex = _selectedIndex < screens.length
            ? _selectedIndex
            : 0;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          body: Row(
            children: [
              Container(
                width: 110,
                color: Colors.white,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.blueAccent,
                      child: Icon(
                        Icons.storefront,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                      ),
                      child: Text(
                        widget.loggedUser ?? 'Usuario',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      role.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    for (var index = 0;
                        index < navigation.length;
                        index++)
                      _navButton(
                        navigation[index].icon,
                        navigation[index].label,
                        index,
                        currentIndex,
                      ),
                    const Spacer(),
                    IconButton(
                      onPressed: _logout,
                      icon: const Icon(
                        Icons.logout,
                        color: Colors.redAccent,
                      ),
                      tooltip: 'Cerrar sesión',
                    ),
                    const Text('Salir'),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              Expanded(child: screens[currentIndex]),
            ],
          ),
        );
      },
    );
  }

  Widget _navButton(
    IconData icon,
    String label,
    int index,
    int currentIndex,
  ) {
    final selected = currentIndex == index;

    return InkWell(
      onTap: () {
        setState(() => _selectedIndex = index);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? Colors.blue.shade700
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : Colors.grey,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: selected ? Colors.white : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

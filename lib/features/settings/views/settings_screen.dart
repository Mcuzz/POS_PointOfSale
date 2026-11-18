import 'package:flutter/material.dart';

import '../../auth/providers/business_repository.dart';
import '../providers/employee_repository.dart';

class SettingsScreen extends StatelessWidget {
  final bool canManageEmployees;

  const SettingsScreen({super.key, this.canManageEmployees = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Administración de empleados'),
            subtitle: const Text('Crear cuentas de cajeros y administradores'),
            trailing: const Icon(Icons.chevron_right),
            onTap: canManageEmployees
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const EmployeeManagementScreen(),
                      ),
                    );
                  }
                : null,
          ),
        ),
      ),
    );
  }
}

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() =>
      _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _businessRepository = BusinessRepository();
  final _employeeRepository = EmployeeRepository();

  String _role = 'cashier';
  bool _saving = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createEmployee() async {
    if (!_formKey.currentState!.validate() || _saving) {
      return;
    }

    setState(() => _saving = true);

    try {
      final businessId = await _businessRepository.getCurrentBusinessId();

      await _employeeRepository.createEmployee(
        businessId: businessId,
        username: _usernameController.text.trim().toLowerCase(),
        password: _passwordController.text,
        role: _role,
      );

      if (!mounted) return;

      _usernameController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Empleado creado correctamente.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      final message = error is StateError
          ? error.message.toString()
          : 'No se pudo crear el empleado. Verifica la conexión y los permisos.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Administración de empleados'),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Crear empleado',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Registra una cuenta para un cajero o administrador.',
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _usernameController,
                        enabled: !_saving,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de usuario',
                          hintText: 'cajero01',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final username = (value ?? '').trim().toLowerCase();

                          if (!RegExp(
                            r'^[a-z0-9_]{3,30}$',
                          ).hasMatch(username)) {
                            return 'Usa entre 3 y 30 caracteres: letras, números o _.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _role,
                        decoration: const InputDecoration(
                          labelText: 'Rol',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'cashier',
                            child: Text('Cajero'),
                          ),
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('Administrador'),
                          ),
                        ],
                        onChanged: _saving
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => _role = value);
                                }
                              },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        enabled: !_saving,
                        obscureText: !_showPassword,
                        decoration: InputDecoration(
                          labelText: 'Contraseña temporal',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() => _showPassword = !_showPassword);
                            },
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if ((value ?? '').length < 12) {
                            return 'La contraseña debe tener al menos 12 caracteres.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        enabled: !_saving,
                        obscureText: !_showPassword,
                        decoration: const InputDecoration(
                          labelText: 'Confirmar contraseña',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return 'Las contraseñas no coinciden.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _saving ? null : _createEmployee,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.person_add),
                        label: Text(
                          _saving ? 'Creando empleado...' : 'Crear empleado',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

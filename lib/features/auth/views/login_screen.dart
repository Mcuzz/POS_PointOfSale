
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth_repository.dart';
import '../../../shared/layouts/main_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authRepo = AuthRepository();

  final _emailController = TextEditingController();
  final _businessController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _employeeMode = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _businessController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    final password = _passwordController.text;

    if (password.isEmpty) {
      _showError('Ingresa tu contraseña.');
      return;
    }

    if (_employeeMode) {
      if (_businessController.text.trim().isEmpty ||
          _usernameController.text.trim().isEmpty) {
        _showError('Ingresa el código de negocio y usuario.');
        return;
      }
    } else if (_emailController.text.trim().isEmpty) {
      _showError('Ingresa tu correo electrónico.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final User? user;

      if (_employeeMode) {
        user = await _authRepo.loginEmployee(
          businessCode: _businessController.text,
          username: _usernameController.text,
          password: password,
        );
      } else {
        user = await _authRepo.login(
          _emailController.text,
          password,
        );
      }

      if (!mounted) return;

      if (user == null) {
        _showError('No se pudo completar el inicio de sesión.');
        return;
      }

      
final loggedUser = _employeeMode
    ? _usernameController.text.trim().toLowerCase()
: (user.email ?? _emailController.text.trim());
Navigator.of(context).pushReplacement(
  MaterialPageRoute<void>(
    builder: (_) => MainLayout(
      loggedUser: loggedUser,
    ),
  ),
);

    } on FunctionException catch (error) {
      if (!mounted) return;

      final details = error.details;
      final message = details is Map
          ? details['error']?.toString()
          : null;

      _showError(message ?? 'No se pudo validar el acceso del empleado.');
    } on AuthApiException catch (error) {
      if (!mounted) return;

      _showError(
        error.code == 'invalid_credentials'
            ? 'Credenciales incorrectas.'
            : 'No se pudo validar el inicio de sesión.',
      );
    } on StateError catch (error) {
      if (!mounted) return;
      _showError(error.message.toString());
    } catch (_) {
      if (!mounted) return;
      _showError('Error de conexión o autenticación.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      enabled: !_isLoading,
      obscureText: obscure && _obscurePassword,
      keyboardType: keyboardType,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        suffixIcon: obscure
            ? IconButton(
                onPressed: () {
                  setState(
                    () => _obscurePassword = !_obscurePassword,
                  );
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
              )
            : null,
      ),
      onSubmitted: obscure ? (_) => _handleLogin() : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blueAccent,
                  child: Icon(
                    Icons.storefront,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Kinetic POS',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Inicia sesión con tus credenciales'),
                const SizedBox(height: 28),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      label: Text('Propietario'),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('Empleado'),
                    ),
                  ],
                  selected: {_employeeMode},
                  onSelectionChanged: _isLoading
                      ? null
                      : (selection) {
                          setState(() {
                            _employeeMode = selection.first;
                            _passwordController.clear();
                          });
                        },
                ),
                const SizedBox(height: 24),
                if (_employeeMode) ...[
                  _field(
                    controller: _businessController,
                    label: 'Código de negocio',
                    icon: Icons.store,
                  ),
                  const SizedBox(height: 16),
                  _field(
                    controller: _usernameController,
                    label: 'Nombre de usuario',
                    icon: Icons.person,
                  ),
                ] else
                  _field(
                    controller: _emailController,
                    label: 'Correo electrónico',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                const SizedBox(height: 16),
                _field(
                  controller: _passwordController,
                  label: 'Contraseña',
                  icon: Icons.lock,
                  obscure: true,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text('ENTRAR'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  void _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    final authService = AuthService();
    await authService.signInWithGoogle();

    // No necesitamos navegar manualmente, el StreamBuilder en main.dart lo hará.
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo o Título
            const Icon(Icons.lock_person, size: 100, color: Colors.blueAccent),
            const SizedBox(height: 20),
            const Text(
              "Bienvenido",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            // Botón de Google
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _handleGoogleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 3,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    icon: const Icon(Icons.g_mobiledata, color: Colors.red, size: 30),
                    label: const Text(
                      "Iniciar sesión con Google",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
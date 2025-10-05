import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Pantalla de redirección que envía al usuario al dashboard.
///
/// Esta pantalla actúa como punto de entrada después de la introducción
/// y redirige automáticamente al usuario al dashboard principal.
class HomeScreen extends StatefulWidget {
  /// Constructor de la pantalla de redirección.
  ///
  /// [key] - Clave opcional para el widget.
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// Estado de la pantalla de redirección.
class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Redirigir al dashboard después de un breve delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go('/dashboard');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A))),
    );
  }
}

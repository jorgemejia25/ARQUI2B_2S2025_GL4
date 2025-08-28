import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Pantalla de introducción que se muestra al iniciar la aplicación.
///
/// Esta pantalla presenta la aplicación al usuario con un banner de imagen
/// de fondo y un panel blanco que contiene el título, descripción y botón
/// para comenzar a usar la aplicación.
///
/// Características:
/// - Banner de imagen de fondo que cubre toda la pantalla
/// - Panel blanco flotante con información de la aplicación
/// - Botón de acción para navegar a la pantalla principal
/// - Diseño responsive que se adapta a diferentes tamaños de pantalla
class IntroScreen extends StatelessWidget {
  /// Constructor de la pantalla de introducción.
  ///
  /// [key] - Clave opcional para el widget.
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Banner que cubre toda la pantalla
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/11/52/4d/ce/vistya-general-del-palacio.jpg?w=1000&h=-1&s=1',
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
              ),
            ),
          ),

          // Contenido principal
          SafeArea(
            child: Column(
              children: [
                // Espacio superior
                const Spacer(),

                // Panel blanco con contenido
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Título principal
                      const Text(
                        'Gestión de Tráfico',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      // Subtítulo
                      const Text(
                        'Sistema inteligente para el control y monitoreo del tráfico urbano',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF64748B),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 32),

                      // Botón principal
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => context.go('/home'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Comenzar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Texto informativo
                      const Text(
                        'Gestiona el tráfico de manera eficiente',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

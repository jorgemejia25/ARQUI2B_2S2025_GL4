import 'package:flutter/material.dart';
import 'routes/app_router.dart';

/// Punto de entrada principal de la aplicación de Gestión de Tráfico.
///
/// Esta función inicia la aplicación Flutter y configura el widget raíz
/// que contendrá toda la interfaz de usuario.
///
/// La aplicación se configura con:
/// - MaterialApp.router para usar go_router
/// - Tema personalizado con colores de la marca
/// - Configuración de rutas centralizada
void main() {
  runApp(const MyApp());
}

/// Widget raíz de la aplicación que configura el tema y la navegación.
///
/// Este widget es responsable de:
/// - Configurar el tema de la aplicación
/// - Establecer la configuración de navegación
/// - Definir el comportamiento global de la aplicación
///
/// Características del tema:
/// - Color principal: Azul oscuro (#1E3A8A)
/// - Material Design 3 habilitado
/// - Fuente Roboto como predeterminada
class MyApp extends StatelessWidget {
  /// Constructor del widget raíz de la aplicación.
  ///
  /// [key] - Clave opcional para el widget.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      /// Título de la aplicación que se muestra en el sistema operativo.
      title: 'Gestión de Tráfico',

      /// Configuración del tema de la aplicación.
      ///
      /// Define los colores, tipografías y estilos que se aplicarán
      /// globalmente en toda la aplicación.
      theme: ThemeData(
        /// Esquema de colores generado a partir del color principal.
        ///
        /// El color seed se usa para generar automáticamente una paleta
        /// de colores coherente y accesible.
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          brightness: Brightness.light,
        ),

        /// Habilita Material Design 3 para un diseño más moderno.
        useMaterial3: true,

        /// Define la fuente predeterminada para toda la aplicación.
        fontFamily: 'Roboto',
      ),

      /// Configuración del router para la navegación de la aplicación.
      ///
      /// Utiliza go_router para manejar la navegación entre pantallas
      /// de manera declarativa y eficiente.
      routerConfig: appRouter,
    );
  }
}

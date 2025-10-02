import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'routes/app_router.dart';
import 'config/app_theme.dart';

/// Punto de entrada principal de la aplicación de Gestión de Tráfico.
///
/// Esta función inicia la aplicación Flutter y configura el widget raíz
/// que contendrá toda la interfaz de usuario.
///
/// La aplicación se configura con:
/// - MaterialApp.router para usar go_router
/// - Tema oscuro moderno con morado y detalles neón
/// - Configuración de rutas centralizada
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar la UI del sistema en modo oscuro
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.backgroundDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

/// Widget raíz de la aplicación que configura el tema y la navegación.
///
/// Este widget es responsable de:
/// - Configurar el tema oscuro moderno
/// - Establecer la configuración de navegación
/// - Definir el comportamiento global de la aplicación
///
/// Características del tema:
/// - Tema oscuro con morado (#8B5CF6) como color principal
/// - Detalles neón para efectos visuales modernos
/// - Material Design 3 habilitado
/// - Diseño tecnológico e innovador
class MyApp extends StatelessWidget {
  /// Constructor del widget raíz de la aplicación.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      /// Título de la aplicación que se muestra en el sistema operativo.
      title: 'Sistema de Seguridad de Tráfico',

      /// Tema oscuro personalizado con diseño moderno neón.
      theme: AppTheme.darkTheme,

      /// Deshabilitar el banner de debug
      debugShowCheckedModeBanner: false,

      /// Configuración del router para la navegación de la aplicación.
      routerConfig: appRouter,
    );
  }
}

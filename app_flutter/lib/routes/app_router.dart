import 'package:go_router/go_router.dart';
import '../screens/intro_screen.dart';
import '../screens/home_screen.dart';
import '../screens/professional_dashboard_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/map_screen.dart';
import '../screens/qr_scanner_screen.dart';
import '../screens/info_screen.dart';
import '../screens/blacklist_screen.dart';
import '../screens/weapons_screen.dart';
import '../screens/plate_detection_screen.dart';

/// Configuración de rutas de la aplicación usando go_router.
///
/// Este archivo define todas las rutas disponibles en la aplicación y
/// mapea cada ruta a su correspondiente pantalla.
///
/// Rutas disponibles:
/// - `/` - Pantalla de introducción (IntroScreen)
/// - `/home` - Pantalla principal con navegación (HomeScreen)
/// - `/dashboard` - Panel de control principal
/// - `/notifications` - Alertas y notificaciones
/// - `/map` - Mapa interactivo
/// - `/qr-scanner` - Escáner de códigos QR
/// - `/info` - Información de la aplicación
///
/// Características:
/// - Navegación declarativa con go_router
/// - Rutas nombradas para navegación programática
/// - Configuración centralizada de navegación
/// - Soporte para deep linking
final GoRouter appRouter = GoRouter(
  /// Ruta inicial de la aplicación.
  ///
  /// Cuando la aplicación se inicia, se muestra la pantalla de introducción.
  initialLocation: '/',

  /// Lista de rutas disponibles en la aplicación.
  ///
  /// Cada ruta define un path, nombre opcional y builder para crear el widget.
  routes: [
    /// Ruta de la pantalla de introducción.
    ///
    /// Esta es la primera pantalla que ve el usuario al abrir la aplicación.
    /// Muestra información sobre la aplicación y un botón para comenzar.
    GoRoute(
      path: '/',
      name: 'intro',
      builder: (context, state) => const IntroScreen(),
    ),

    /// Ruta de la pantalla principal.
    ///
    /// Esta es la pantalla principal de la aplicación que contiene
    /// el drawer de navegación y todas las funcionalidades del sistema.
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),

    /// Ruta del dashboard profesional.
    ///
    /// Pantalla del panel de control avanzado con análisis en tiempo real,
    /// filtros personalizados y gráficas profesionales.
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => const ProfessionalDashboardScreen(),
    ),

    /// Ruta de notificaciones.
    ///
    /// Pantalla que muestra alertas y notificaciones del sistema
    /// relacionadas con el estado del tráfico.
    GoRoute(
      path: '/notifications',
      name: 'notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),

    /// Ruta del mapa interactivo.
    ///
    /// Pantalla que muestra la simulación de paradas en tiempo real
    /// y el estado del tráfico en un mapa interactivo.
    GoRoute(
      path: '/map',
      name: 'map',
      builder: (context, state) => const MapScreen(),
    ),

    /// Ruta del escáner QR.
    ///
    /// Pantalla que permite escanear códigos QR para obtener
    /// información turística de los puntos de interés.
    GoRoute(
      path: '/qr-scanner',
      name: 'qr-scanner',
      builder: (context, state) => const QRScannerScreen(),
    ),

    /// Ruta de información.
    ///
    /// Pantalla que muestra información sobre la aplicación,
    /// incluyendo versión, desarrolladores y términos de uso.
    GoRoute(
      path: '/info',
      name: 'info',
      builder: (context, state) => const InfoScreen(),
    ),

    /// Ruta de lista negra.
    ///
    /// Pantalla que muestra eventos de detección de personas
    /// en lista negra con historial completo y filtros.
    GoRoute(
      path: '/blacklist',
      name: 'blacklist',
      builder: (context, state) => const BlacklistScreen(),
    ),

    /// Ruta de armas blancas.
    ///
    /// Pantalla que muestra eventos de detección de armas blancas
    /// con historial completo y top por frecuencia.
    GoRoute(
      path: '/weapons',
      name: 'weapons',
      builder: (context, state) => const WeaponsScreen(),
    ),

    GoRoute(
      path: '/plates',
      name: 'plates',
      builder: (context, state) => const PlateDetectionScreen(),
    ),    
  ],
);

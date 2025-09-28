import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Layout principal de la aplicación que maneja el scaffold y drawer.
///
/// Este widget proporciona la estructura base para todas las pantallas
/// de la aplicación, incluyendo la AppBar, Drawer y el contenido dinámico.
class MainLayout extends StatelessWidget {
  /// Constructor del layout principal.
  ///
  /// [key] - Clave opcional para el widget.
  /// [title] - Título que se mostrará en la AppBar.
  /// [child] - Contenido que se mostrará en el body del scaffold.
  const MainLayout({super.key, required this.title, required this.child});

  /// Título que se mostrará en la AppBar.
  final String title;

  /// Contenido que se mostrará en el body del scaffold.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: _buildDrawer(context),
      body: child,
    );
  }

  /// Construye el drawer lateral de navegación.
  ///
  /// El drawer incluye:
  /// - Header con logo y título de la aplicación
  /// - Lista de opciones de navegación
  /// - Footer con opción de configuración
  ///
  /// Parameters:
  ///   [context] - Contexto de la aplicación para navegación.
  ///
  /// Returns:
  ///   Un widget Drawer configurado con la navegación de la aplicación.
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Header simple del drawer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              decoration: const BoxDecoration(color: Color(0xFF1E3A8A)),
              child: const Column(
                children: [
                  Icon(Icons.traffic, size: 50, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    'Gestión de Tráfico',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Lista de opciones de navegación simplificada
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    context,
                    icon: Icons.dashboard,
                    title: 'Dashboard',
                    route: '/dashboard',
                    isSelected: title == 'Dashboard',
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.notifications,
                    title: 'Notificaciones',
                    route: '/notifications',
                    isSelected: title == 'Notificaciones',
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.map,
                    title: 'Mapa Interactivo',
                    route: '/map',
                    isSelected: title == 'Mapa Interactivo',
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.qr_code_scanner,
                    title: 'Escáner QR',
                    route: '/qr-scanner',
                    isSelected: title == 'Escáner QR',
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.info,
                    title: 'Información',
                    route: '/info',
                    isSelected: title == 'Información',
                  ),
                ],
              ),
            ),

            // Footer simple
            Container(
              padding: const EdgeInsets.all(20),
              child: const Row(
                children: [
                  Icon(Icons.settings, color: Color(0xFF64748B), size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Configuración',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye un elemento individual del drawer de navegación.
  ///
  /// Cada elemento muestra un icono, título y maneja la navegación.
  ///
  /// Parameters:
  ///   [context] - Contexto para la navegación.
  ///   [icon] - Icono a mostrar en el elemento.
  ///   [title] - Título del elemento de navegación.
  ///   [route] - Ruta a la que navegar.
  ///   [isSelected] - Indica si este elemento está seleccionado.
  ///
  /// Returns:
  ///   Un widget ListTile configurado para la navegación.
  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    bool isSelected = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF64748B),
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF1E3A8A),
        ),
      ),
      selected: isSelected,
      selectedTileColor: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
      onTap: () {
        context.go(route);
        Navigator.pop(context);
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';

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
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppTheme.purpleGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                boxShadow: AppTheme.neonShadow(
                  AppTheme.primaryPurple,
                  blur: 10,
                ),
              ),
              child: const Icon(
                Icons.flash_on_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(title, style: AppTheme.headingMedium),
          ],
        ),
        backgroundColor: AppTheme.backgroundCard.withOpacity(0.8),
        elevation: 0,
        centerTitle: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu_rounded, color: AppTheme.primaryPurple),
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
      backgroundColor: AppTheme.backgroundCard,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.backgroundCard, AppTheme.backgroundDark],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Header moderno del drawer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
              decoration: BoxDecoration(
                gradient: AppTheme.purpleGradient,
                boxShadow: AppTheme.neonShadow(
                  AppTheme.primaryPurple,
                  blur: 20,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.flash_on_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sistema de',
                    style: AppTheme.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Seguridad de Tráfico',
                    style: AppTheme.headingMedium.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Lista de opciones de navegación
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spaceMedium,
                  horizontal: AppTheme.spaceSmall,
                ),
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

            // Footer moderno
            Container(
              margin: const EdgeInsets.all(AppTheme.spaceMedium),
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              decoration: BoxDecoration(
                color: AppTheme.backgroundElevated.withOpacity(0.5),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: AppTheme.primaryPurple.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.settings_rounded,
                    color: AppTheme.primaryPurpleLight,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Configuración',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
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
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: AppTheme.spaceXSmall,
        horizontal: AppTheme.spaceSmall,
      ),
      decoration: BoxDecoration(
        gradient: isSelected ? AppTheme.purpleGradient : null,
        color: isSelected ? null : AppTheme.backgroundElevated.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: isSelected
              ? AppTheme.primaryPurple.withOpacity(0.5)
              : AppTheme.greyMedium.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: isSelected
            ? AppTheme.neonShadow(AppTheme.primaryPurple, blur: 15)
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMedium,
          vertical: AppTheme.spaceXSmall,
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withOpacity(0.2)
                : AppTheme.greyDark,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : AppTheme.primaryPurpleLight,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
        trailing: isSelected
            ? Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 16,
              )
            : null,
        selected: isSelected,
        onTap: () {
          context.go(route);
          Navigator.pop(context);
        },
      ),
    );
  }
}

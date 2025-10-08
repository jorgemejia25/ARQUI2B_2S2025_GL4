import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/bottom_nav_bar.dart';

/// Layout moderno inspirado en shadcn con diseño limpio
class ModernLayout extends StatelessWidget {
  final String title;
  final Widget child;
  final String currentRoute;
  final bool showBottomNav;
  final List<Widget>? actions;

  const ModernLayout({
    super.key,
    required this.title,
    required this.child,
    required this.currentRoute,
    this.showBottomNav = true,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Column(
        children: [
          // Header moderno
          _buildHeader(context),

          // Contenido principal
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(color: AppTheme.backgroundDark),
              child: child,
            ),
          ),
        ],
      ),
      bottomNavigationBar: showBottomNav
          ? ModernBottomNavBar(currentRoute: currentRoute)
          : null,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.greyMedium.withOpacity(0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceMedium,
            AppTheme.spaceMedium,
            AppTheme.spaceMedium,
            AppTheme.spaceMedium,
          ),
          child: Row(
            children: [
              // Logo/Icono
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppTheme.purpleGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryPurple.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.flash_on_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),

              const SizedBox(width: AppTheme.spaceMedium),

              // Título
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.headingMedium.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Sistema de Seguridad',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Acciones
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }
}

/// Layout para pantallas que necesitan scroll
class ModernScrollLayout extends StatelessWidget {
  final String title;
  final Widget child;
  final String currentRoute;
  final bool showBottomNav;
  final List<Widget>? actions;
  final Future<void> Function()? onRefresh;

  const ModernScrollLayout({
    super.key,
    required this.title,
    required this.child,
    required this.currentRoute,
    this.showBottomNav = true,
    this.actions,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return ModernLayout(
      title: title,
      currentRoute: currentRoute,
      showBottomNav: showBottomNav,
      actions: actions,
      child: onRefresh != null
          ? RefreshIndicator(
              onRefresh: onRefresh!,
              color: AppTheme.primaryPurple,
              backgroundColor: AppTheme.backgroundCard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: child,
              ),
            )
          : SingleChildScrollView(child: child),
    );
  }
}

/// Container moderno para contenido
class ModernContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool hasBorder;

  const ModernContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.hasBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(AppTheme.spaceMedium),
      padding: padding ?? const EdgeInsets.all(AppTheme.spaceLarge),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: hasBorder
            ? Border.all(color: AppTheme.greyMedium.withOpacity(0.2), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Card moderno para métricas
class ModernMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const ModernMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            value,
            style: AppTheme.headingLarge.copyWith(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: AppTheme.spaceXSmall),
          Text(
            title,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
















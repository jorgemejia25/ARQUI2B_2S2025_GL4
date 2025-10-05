import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';

/// Bottom navigation bar moderno inspirado en shadcn
class ModernBottomNavBar extends StatelessWidget {
  final String currentRoute;

  const ModernBottomNavBar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        border: Border(
          top: BorderSide(
            color: AppTheme.greyMedium.withOpacity(0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMedium,
            vertical: AppTheme.spaceSmall,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                route: '/dashboard',
                isActive: currentRoute == '/dashboard',
              ),
              _buildNavItem(
                context,
                icon: Icons.notifications_rounded,
                label: 'Alertas',
                route: '/notifications',
                isActive: currentRoute == '/notifications',
              ),
              _buildNavItem(
                context,
                icon: Icons.map_rounded,
                label: 'Mapa',
                route: '/map',
                isActive: currentRoute == '/map',
              ),
              _buildNavItem(
                context,
                icon: Icons.qr_code_scanner_rounded,
                label: 'QR',
                route: '/qr-scanner',
                isActive: currentRoute == '/qr-scanner',
              ),
              _buildNavItem(
                context,
                icon: Icons.info_rounded,
                label: 'Info',
                route: '/info',
                isActive: currentRoute == '/info',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMedium,
          vertical: AppTheme.spaceSmall,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryPurple.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: isActive
              ? Border.all(
                  color: AppTheme.primaryPurple.withOpacity(0.3),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.primaryPurple.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isActive
                    ? AppTheme.primaryPurple
                    : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTheme.caption.copyWith(
                color: isActive
                    ? AppTheme.primaryPurple
                    : AppTheme.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}












import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';

/// Bottom navigation bar moderno inspirado en shadcn
class ModernBottomNavBar extends StatelessWidget {
  final String currentRoute;

  const ModernBottomNavBar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

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
            horizontal: AppTheme.spaceSmall,
            vertical: AppTheme.spaceSmall,
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildNavItem(
                  context,
                  icon: Icons.dashboard_rounded,
                  label: isSmallScreen ? 'Dash' : 'Dashboard',
                  route: '/dashboard',
                  isActive: currentRoute == '/dashboard',
                  isSmallScreen: isSmallScreen,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  context,
                  icon: Icons.notifications_rounded,
                  label: isSmallScreen ? 'Alertas' : 'Alertas',
                  route: '/notifications',
                  isActive: currentRoute == '/notifications',
                  isSmallScreen: isSmallScreen,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  context,
                  icon: Icons.map_rounded,
                  label: isSmallScreen ? 'Mapa' : 'Mapa',
                  route: '/map',
                  isActive: currentRoute == '/map',
                  isSmallScreen: isSmallScreen,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  context,
                  icon: Icons.person_off_rounded,
                  label: isSmallScreen ? 'Lista' : 'Lista Negra',
                  route: '/blacklist',
                  isActive: currentRoute == '/blacklist',
                  isSmallScreen: isSmallScreen,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  context,
                  icon: Icons.qr_code_scanner_rounded,
                  label: isSmallScreen ? 'QR' : 'QR',
                  route: '/qr-scanner',
                  isActive: currentRoute == '/qr-scanner',
                  isSmallScreen: isSmallScreen,
                ),
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
    bool isSmallScreen = false,
  }) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen
              ? AppTheme.spaceXSmall
              : AppTheme.spaceSmall,
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
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.primaryPurple.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(
                icon,
                size: isSmallScreen ? 16 : 18,
                color: isActive
                    ? AppTheme.primaryPurple
                    : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                label,
                style: AppTheme.caption.copyWith(
                  color: isActive
                      ? AppTheme.primaryPurple
                      : AppTheme.textSecondary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  fontSize: isSmallScreen ? 10 : 11,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

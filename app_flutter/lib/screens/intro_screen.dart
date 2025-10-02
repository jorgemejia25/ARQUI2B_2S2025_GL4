import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';

/// Pantalla de introducción simple y limpia
class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Título principal
              Text(
                'Sistema de Seguridad de Tráfico',
                style: AppTheme.headingLarge.copyWith(
                  fontSize: 32,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppTheme.spaceXLarge * 2),

              // Botón de iniciar
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.go('/dashboard'),
                  style:
                      ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMedium,
                          ),
                        ),
                      ).copyWith(
                        overlayColor: MaterialStateProperty.all(
                          AppTheme.primaryPurple.withOpacity(0.1),
                        ),
                      ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.purpleGradient,
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryPurple.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Iniciar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/weapon_event.dart';
import '../utils/weapon_utils.dart';
import '../config/app_theme.dart';

class WeaponEventCard extends StatelessWidget {
  final WeaponEvent event;
  const WeaponEventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final nameEs = WeaponUtils.toSpanish(event.nameEn);
    final asset = WeaponUtils.assetFor(event.nameEn);

    return Container
    (
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icono a la izquierda
          Image.asset(
            asset,
            width: 44,
            height: 44,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),

          // Información a la derecha
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nameEs,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(event.ts),
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.social_distance_rounded, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      _formatDistance(event.distance),
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.videocam_rounded, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.cameraLocation ?? 'Cámara',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime ts) {
    final h = ts.hour.toString().padLeft(2, '0');
    final m = ts.minute.toString().padLeft(2, '0');
    final s = ts.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatDistance(double d) {
    // si la IA está calibrada, es cm; si no, podría ser px
    // asumimos cm por tu flujo
    return '${d.toStringAsFixed(1)} cm';
  }
}

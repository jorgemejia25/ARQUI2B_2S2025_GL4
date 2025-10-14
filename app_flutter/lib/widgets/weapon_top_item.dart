import 'package:flutter/material.dart';
import '../models/weapon_count.dart';
import '../utils/weapon_utils.dart';
import '../config/app_theme.dart';

class WeaponTopItem extends StatelessWidget {
  final WeaponCount item;
  const WeaponTopItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final nameEs = WeaponUtils.toSpanish(item.nameEn);
    final asset = WeaponUtils.assetFor(item.nameEn);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Image.asset(
            asset,
            width: 40,
            height: 40,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: AppTheme.purpleGradient,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Top ${item.top}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      nameEs,
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Cantidad: ${item.count}',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

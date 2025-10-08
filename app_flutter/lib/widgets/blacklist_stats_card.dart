import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Widget para mostrar estadísticas de una persona en la blacklist
class BlacklistStatsCard extends StatelessWidget {
  final String personName;
  final int totalDetections;
  final double avgConfidence;
  final String lastDetection;
  final int rank;
  final VoidCallback? onTap;

  const BlacklistStatsCard({
    super.key,
    required this.personName,
    required this.totalDetections,
    required this.avgConfidence,
    required this.lastDetection,
    required this.rank,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.backgroundCard, AppTheme.backgroundElevated],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getRankColor().withOpacity(0.3), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Rank badge
                _buildRankBadge(),
                const SizedBox(width: 12),

                // Avatar with image
                _buildAvatar(),
                const SizedBox(width: 12),

                // Person info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        personName.replaceAll('_', ' '),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.visibility_rounded,
                            size: 12,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$totalDetections ${totalDetections == 1 ? 'detección' : 'detecciones'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Stats
                _buildStats(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRankBadge() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_getRankColor(), _getRankColor().withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '#$rank',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getRankColor().withOpacity(0.5), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: _buildPersonImage(),
      ),
    );
  }

  Widget _buildPersonImage() {
    // Determinar la extensión basada en el nombre de la persona
    String imagePath;

    if (personName.contains('PAUL') || personName.contains('Paul')) {
      imagePath = 'assets/gallery/$personName/1.png';
    } else {
      imagePath = 'assets/gallery/$personName/1.jpeg';
    }

    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Intentar con otra extensión
        final alternativePath = _getAlternativeImagePath();

        return Image.asset(
          alternativePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackAvatar();
          },
        );
      },
    );
  }

  String _getAlternativeImagePath() {
    // Si falló la primera opción, intentar con la otra extensión
    if (personName.contains('PAUL') || personName.contains('Paul')) {
      return 'assets/gallery/$personName/1.jpeg'; // Intentar jpeg si png falló
    } else {
      return 'assets/gallery/$personName/1.png'; // Intentar png si jpeg falló
    }
  }

  Widget _buildFallbackAvatar() {
    return Container(
      color: AppTheme.primaryPurple.withOpacity(0.2),
      child: Icon(
        Icons.person_rounded,
        color: AppTheme.primaryPurple,
        size: 24,
      ),
    );
  }

  Widget _buildStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.neonGreen.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.analytics_rounded,
                size: 12,
                color: AppTheme.neonGreen,
              ),
              const SizedBox(width: 4),
              Text(
                '${(avgConfidence * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.neonGreen,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          lastDetection,
          style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Color _getRankColor() {
    switch (rank) {
      case 1:
        return AppTheme.neonYellow; // Oro
      case 2:
        return AppTheme.textSecondary; // Plata
      case 3:
        return AppTheme.neonOrange; // Bronce
      default:
        return AppTheme.primaryPurple;
    }
  }
}

import 'package:flutter/material.dart';
import '../layouts/main_layout.dart';

/// Pantalla de información que muestra detalles sobre la aplicación.
///
/// Esta pantalla proporciona información sobre la aplicación, incluyendo
/// versión, desarrolladores, términos de uso y política de privacidad.
class InfoScreen extends StatelessWidget {
  /// Constructor de la pantalla de información.
  ///
  /// [key] - Clave opcional para el widget.
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Información',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.school, size: 80, color: Color(0xFF1E3A8A)),
            const SizedBox(height: 24),
            const Text(
              'Sistema de Seguridad de Tráfico',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Aplicación de monitoreo y control de semáforos',
              style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Información Académica',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    'Materia:',
                    'Arquitectura de Computadoras y Ensambladores 2',
                  ),
                  _buildInfoRow('Grupo:', 'Grupo 4'),
                  _buildInfoRow('Profesor:', 'Marcos Barrios'),
                  const SizedBox(height: 20),
                  const Text(
                    'Integrantes del Equipo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMemberList(),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF1E3A8A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF1E3A8A), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta aplicación permite el monitoreo en tiempo real de semáforos y paradas de autobús mediante tecnología MQTT y WebSocket.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF1E3A8A)),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberList() {
    final members = [
      'Valery Alarcón',
      'Damián Orozco',
      'Fátima Cerezo',
      'Juan Chacón',
      'Jorge Mejía',
      'Julio Escobar',
      'Diego González',
    ];

    return Column(
      children: members.map((member) => _buildMemberItem(member)).toList(),
    );
  }

  Widget _buildMemberItem(String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A8A),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            name,
            style: const TextStyle(fontSize: 16, color: Color(0xFF374151)),
          ),
        ],
      ),
    );
  }
}

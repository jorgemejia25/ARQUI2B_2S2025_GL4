import 'package:flutter/material.dart';
import '../layouts/main_layout.dart';

/// Pantalla del escáner QR para obtener información turística.
///
/// Esta pantalla permite a los usuarios escanear códigos QR ubicados en
/// puntos turísticos para obtener información detallada sobre cada lugar.
class QRScannerScreen extends StatelessWidget {
  /// Constructor de la pantalla del escáner QR.
  ///
  /// [key] - Clave opcional para el widget.
  const QRScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Escáner QR',
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_scanner, size: 80, color: Color(0xFF1E3A8A)),
            SizedBox(height: 24),
            Text(
              'Escáner QR',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Escanear códigos QR para\ninformación turística',
              style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

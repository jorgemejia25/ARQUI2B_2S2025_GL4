import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../layouts/main_layout.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});
  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController? controller;
  String? lastValue;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      // Verificar permisos de cámara
      final status = await Permission.camera.status;
      if (status.isDenied) {
        final result = await Permission.camera.request();
        if (result.isDenied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Se requieren permisos de cámara para escanear QR',
                ),
              ),
            );
          }
          return;
        }
      }

      if (status.isPermanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Los permisos de cámara están permanentemente denegados',
              ),
            ),
          );
        }
        return;
      }

      controller = MobileScannerController(
        facing: CameraFacing.back,
        torchEnabled: false,
      );
      setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al inicializar la cámara: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    try {
      controller?.dispose();
    } catch (e) {
      print('Error al liberar el controlador de la cámara: $e');
    }
    super.dispose();
  }

  Future<void> _launchURL(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace')),
      );
    }
  }

  Uri? _toUri(String? v) {
    if (v == null) return null;
    final withScheme = v.startsWith('http://') || v.startsWith('https://')
        ? v
        : 'https://$v';
    final u = Uri.tryParse(withScheme);
    if (u == null) return null;
    if (u.scheme == 'http' || u.scheme == 'https') return u;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFF1E3A8A);

    final Uri? url = _toUri(lastValue);
    final bool canOpen = url != null;

    return MainLayout(
      title: 'Escáner QR',
      child: Column(
        children: [
          const SizedBox(height: 12),

          SizedBox(
            height: 580,
            child: Stack(
              children: [
                Positioned.fill(
                  child: _isInitialized && controller != null
                      ? MobileScanner(
                          controller: controller!,
                          onDetect: (capture) {
                            try {
                              final barcode = capture.barcodes.first;
                              final value = barcode.rawValue;
                              if (value != null && value != lastValue) {
                                setState(() => lastValue = value);
                              }
                            } catch (e) {
                              print('Error procesando código QR: $e');
                            }
                          },
                        )
                      : _isInitialized == false
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                size: 64,
                                color: Color(0xFF1E3A8A),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Inicializando cámara...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Error al acceder a la cámara',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                // Marco central
                Center(
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
                // Controles
                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    children: [
                      _roundBtn(
                        icon: Icons.flashlight_on,
                        onTap: () => controller?.toggleTorch(),
                      ),
                      const SizedBox(width: 8),
                      _roundBtn(
                        icon: Icons.cameraswitch,
                        onTap: () => controller?.switchCamera(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Texto con el último QR
          if (lastValue != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Último QR: $lastValue',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: brand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          if (canOpen) ...[
            const SizedBox(height: 12),
            Text(
              url.host, // dominio del link
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: brand,
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Botón IR AL LINK
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canOpen ? Colors.green : Colors.grey,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: canOpen ? () => _launchURL(url) : null,
                child: const Text(
                  'Ir al Link',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _roundBtn({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.25),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white70),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

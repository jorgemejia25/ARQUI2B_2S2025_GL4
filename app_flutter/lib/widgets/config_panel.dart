import 'package:flutter/material.dart';
import '../services/config_service.dart';

/// Panel de configuración para cambiar URLs y entorno
class ConfigPanel extends StatefulWidget {
  const ConfigPanel({super.key});

  @override
  State<ConfigPanel> createState() => _ConfigPanelState();
}

class _ConfigPanelState extends State<ConfigPanel> {
  final ConfigService _configService = ConfigService.instance;
  final TextEditingController _baseUrlController = TextEditingController();
  final TextEditingController _wsUrlController = TextEditingController();

  String _currentEnvironment = 'development';
  String _currentBaseUrl = '';
  String _currentWsUrl = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  Future<void> _loadCurrentConfig() async {
    setState(() => _isLoading = true);

    await _configService.initialize();
    final config = _configService.getCurrentConfig();

    setState(() {
      _currentEnvironment = config['environment'] as String;
      _currentBaseUrl = config['baseUrl'] as String;
      _currentWsUrl = config['wsBaseUrl'] as String;
      _baseUrlController.text = _currentBaseUrl;
      _wsUrlController.text = _currentWsUrl;
      _isLoading = false;
    });
  }

  Future<void> _switchToDevelopment() async {
    await _configService.switchToDevelopment();
    await _loadCurrentConfig();
    _showSnackBar('Cambiado a modo desarrollo');
  }

  Future<void> _switchToProduction() async {
    await _configService.switchToProduction();
    await _loadCurrentConfig();
    _showSnackBar('Cambiado a modo producción');
  }

  Future<void> _setCustomUrls() async {
    final baseUrl = _baseUrlController.text.trim();
    final wsUrl = _wsUrlController.text.trim();

    if (baseUrl.isEmpty || wsUrl.isEmpty) {
      _showSnackBar('Por favor completa ambas URLs', isError: true);
      return;
    }

    if (!_configService.isValidUrl(baseUrl) ||
        !_configService.isValidUrl(wsUrl)) {
      _showSnackBar('URLs inválidas', isError: true);
      return;
    }

    await _configService.setCustomBaseUrl(baseUrl);
    await _configService.setCustomWsUrl(wsUrl);
    await _loadCurrentConfig();
    _showSnackBar('URLs personalizadas establecidas');
  }

  Future<void> _clearCustomUrls() async {
    await _configService.clearCustomUrls();
    await _loadCurrentConfig();
    _showSnackBar('URLs personalizadas limpiadas');
  }

  Future<void> _resetToDefaults() async {
    await _configService.resetToDefaults();
    await _loadCurrentConfig();
    _showSnackBar('Configuración reseteada');
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de API'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información actual
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configuración Actual',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Entorno: $_currentEnvironment'),
                    Text('URL Base: $_currentBaseUrl'),
                    Text('URL WebSocket: $_currentWsUrl'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Cambio de entorno
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cambiar Entorno',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _currentEnvironment == 'development'
                                ? null
                                : _switchToDevelopment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _currentEnvironment == 'development'
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            child: const Text('Desarrollo'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _currentEnvironment == 'production'
                                ? null
                                : _switchToProduction,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _currentEnvironment == 'production'
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            child: const Text('Producción'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // URLs personalizadas
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'URLs Personalizadas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _baseUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL Base (HTTP/HTTPS)',
                        hintText: 'http://192.168.1.158:8001',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _wsUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL WebSocket (WS/WSS)',
                        hintText: 'ws://192.168.1.158:8001',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _setCustomUrls,
                            child: const Text('Establecer URLs'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _clearCustomUrls,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                            child: const Text('Limpiar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Acciones adicionales
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Acciones Adicionales',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _resetToDefaults,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Resetear a Valores por Defecto'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Información de servicios
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'URLs de Servicios',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._configService.getServiceUrls().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 80,
                              child: Text(
                                '${entry.key}:',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _wsUrlController.dispose();
    super.dispose();
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import '../layouts/modern_layout.dart';
import '../config/app_theme.dart';
import '../models/plate_event.dart';
import '../services/plate_event_service.dart';
import '../widgets/plate_event_card.dart';

class PlateDetectionScreen extends StatefulWidget {
  const PlateDetectionScreen({super.key});

  @override
  State<PlateDetectionScreen> createState() => _PlateDetectionScreenState();
}

class _PlateDetectionScreenState extends State<PlateDetectionScreen> {
  final _service = PlateEventService.instance;
  final _scrollController = ScrollController();
  List<PlateEvent> _events = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final events = await _service.fetchEvents(limit: 50);
      setState(() => _events = events);
    } catch (e) {
      print('[PlateDetectionScreen] Error loading events: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando eventos: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showPlateDetails(PlateEvent event) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.backgroundCard, AppTheme.backgroundElevated],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryPurple.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.purpleGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.directions_car_filled_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Evento de Placa Detectada',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            event.plateText,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Contenido con imagen
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (event.imageBase64 != null &&
                        event.imageBase64!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          base64Decode(event.imageBase64!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    else
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundElevated.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported_rounded,
                            color: AppTheme.textSecondary,
                            size: 50,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Confianza:',
                        '${(event.confidence * 100).toStringAsFixed(1)}%'),
                    _buildDetailRow('Cámara:',
                        event.cameraLocation ?? 'No especificada'),
                    _buildDetailRow(
                        'Fecha y Hora:', event.formattedTimestamp ?? '-'),
                  ],
                ),
              ),

              // Botón cerrar
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundElevated,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.backgroundElevated.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryPurple,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ModernLayout(
      title: 'Detección de Placas',
      currentRoute: '/plates',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEvents,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _events.length,
                itemBuilder: (context, index) {
                  final event = _events[index];
                  return GestureDetector(
                    onTap: () => _showPlateDetails(event),
                    child: PlateEventCard(event: event),
                  );
                },
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import '../services/bus_stop_service.dart';
import '../models/bus_stop.dart';

class EtaInfoModal extends StatelessWidget {
  const EtaInfoModal({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, BusStopEtaInfo>>(
      stream: BusStopService.instance.busStopsStream,
      builder: (context, snapshot) {
        final busStopsEta =
            snapshot.data ?? BusStopService.instance.getAllBusStopsEta();

        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Header con AppBar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.directions_bus,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Paradas',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        color: Colors.white,
                        iconSize: 24,
                      ),
                    ],
                  ),
                ),

                // Lista de paradas
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: busStopsEta.length,
                    itemBuilder: (context, index) {
                      final entry = busStopsEta.entries.elementAt(index);
                      final stopId = entry.key;
                      final etaInfo = entry.value;
                      return _buildBusStopCard(stopId, etaInfo);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBusStopCard(String stopId, BusStopEtaInfo etaInfo) {
    final hasActiveEta = etaInfo.hasActiveEta;
    final latestEta = etaInfo.latestEta;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header de la parada
            Row(
              children: [
                // Icono de parada
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getStopColor(etaInfo.busStop.state),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.directions_bus,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Información básica
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        etaInfo.busStop.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        etaInfo.busStop.location,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // Estado de la parada
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStopColor(
                      etaInfo.busStop.state,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStopColor(
                        etaInfo.busStop.state,
                      ).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _getStopStateText(etaInfo.busStop.state),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getStopColor(etaInfo.busStop.state),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Información de ETA
            if (hasActiveEta && latestEta != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.schedule, color: Colors.blue[600], size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Próximo Bus',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                latestEta.tipoTransporte,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'Desde ${latestEta.origen}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[600],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            latestEta.tiempoFormateado,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Historial de ETAs
              if (etaInfo.etaUpdates.length > 1) ...[
                const SizedBox(height: 8),
                Text(
                  'Historial de Llegadas',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                ...etaInfo.etaUpdatesSorted
                    .skip(1)
                    .take(3)
                    .map(
                      (eta) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${eta.tipoTransporte} - ${eta.tiempoFormateado}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ] else ...[
              // Sin ETA activo
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[500], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'No hay buses en camino',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStopColor(BusStopState state) {
    switch (state) {
      case BusStopState.active:
        return Colors.green; // Transmetro
      case BusStopState.busy:
        return Colors.blue; // Transurbano
      case BusStopState.waiting:
        return Colors.amber;
      case BusStopState.inactive:
        return Colors.grey;
    }
  }

  String _getStopStateText(BusStopState state) {
    switch (state) {
      case BusStopState.active:
        return 'Transmetro';
      case BusStopState.busy:
        return 'Transurbano';
      case BusStopState.waiting:
        return 'Esperando';
      case BusStopState.inactive:
        return 'Inactiva';
    }
  }
}

import 'package:flutter/material.dart';
import '../services/bus_stop_service.dart';
import '../models/bus_stop.dart';

class BusStopEtaWidget extends StatelessWidget {
  final String stopId;
  final Offset position;

  const BusStopEtaWidget({
    super.key,
    required this.stopId,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, BusStopEtaInfo>>(
      stream: BusStopService.instance.busStopsStream,
      builder: (context, snapshot) {
        final busStopsEta =
            snapshot.data ?? BusStopService.instance.getAllBusStopsEta();
        final etaInfo = busStopsEta[stopId];

        if (etaInfo == null || !etaInfo.hasActiveEta) {
          return const SizedBox.shrink();
        }

        final latestEta = etaInfo.latestEta;
        if (latestEta == null) {
          return const SizedBox.shrink();
        }

        return Positioned(
          left: position.dx,
          top: position.dy,
          child: _buildEtaCard(latestEta, etaInfo.busStop),
        );
      },
    );
  }

  Widget _buildEtaCard(EtaUpdate eta, BusStop busStop) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 120),
      child: Card(
        elevation: 4,
        color: Colors.white.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre de la parada
              Text(
                busStop.displayName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),

              // Tipo de transporte
              Text(
                eta.tipoTransporte,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),

              // Tiempo de llegada
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule, size: 12, color: Colors.green),
                  const SizedBox(width: 2),
                  Text(
                    eta.tiempoFormateado,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),

              // Origen (si hay espacio)
              if (eta.origen.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Desde ${eta.origen}',
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget para mostrar múltiples paradas de bus con ETA
class BusStopsEtaOverlay extends StatelessWidget {
  // Posiciones aproximadas de las paradas en el mapa (ajustar según el SVG)
  static const Map<String, Offset> busStopPositions = {
    'P1': Offset(50, 100),
    'P2_2': Offset(200, 150),
    'P3': Offset(150, 250),
    'P4': Offset(300, 200),
  };

  const BusStopsEtaOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: busStopPositions.entries.map((entry) {
        return BusStopEtaWidget(stopId: entry.key, position: entry.value);
      }).toList(),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/bus_stop.dart';

class BusStopModal extends StatefulWidget {
  final Function(String, BusStopState) onBusStopChanged;
  final Map<String, BusStopState> currentStates;

  const BusStopModal({
    super.key,
    required this.onBusStopChanged,
    required this.currentStates,
  });

  @override
  State<BusStopModal> createState() => _BusStopModalState();
}

class _BusStopModalState extends State<BusStopModal> {
  late Map<String, BusStopState> _localStates;

  @override
  void initState() {
    super.initState();
    _localStates = Map.from(widget.currentStates);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Control de Paradas de Autobús',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Selecciona el estado para cada parada:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: 4,
                itemBuilder: (context, index) {
                  final stopId = ['P1', 'P2', 'P3', 'P4'][index];
                  final currentState =
                      _localStates[stopId] ?? BusStopState.inactive;

                  return _buildBusStopControl(stopId, currentState);
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      for (int i = 1; i <= 4; i++) {
                        _localStates['P$i'] = BusStopState.active;
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Todas Activas'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      for (int i = 1; i <= 4; i++) {
                        _localStates['P$i'] = BusStopState.busy;
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Todas Ocupadas'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      for (int i = 1; i <= 4; i++) {
                        _localStates['P$i'] = BusStopState.inactive;
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Todas Inactivas'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Aplicar todos los cambios
                  _localStates.forEach((id, state) {
                    widget.onBusStopChanged(id, state);
                  });
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  'Aplicar Cambios',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusStopControl(String id, BusStopState currentState) {
    final stopNames = {
      'P1': 'Parada 1\nCentro Norte',
      'P2': 'Parada 2\nCentro Sur',
      'P3': 'Parada 3\nEste',
      'P4': 'Parada 4\nOeste',
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Text(
            stopNames[id] ?? id,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStateButton(id, BusStopState.active, Colors.green, 'A'),
              _buildStateButton(id, BusStopState.inactive, Colors.grey, 'I'),
              _buildStateButton(id, BusStopState.busy, Colors.red, 'O'),
              _buildStateButton(id, BusStopState.waiting, Colors.amber, 'E'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStateButton(
    String id,
    BusStopState state,
    Color color,
    String label,
  ) {
    final isSelected = _localStates[id] == state;

    return GestureDetector(
      onTap: () {
        setState(() {
          _localStates[id] = state;
        });
      },
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[400]!,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}


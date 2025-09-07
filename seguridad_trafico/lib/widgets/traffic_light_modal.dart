import 'package:flutter/material.dart';
import '../models/traffic_light.dart';

class TrafficLightModal extends StatefulWidget {
  final Function(String, TrafficLightState) onTrafficLightChanged;
  final Map<String, TrafficLightState> currentStates;

  const TrafficLightModal({
    super.key,
    required this.onTrafficLightChanged,
    required this.currentStates,
  });

  @override
  State<TrafficLightModal> createState() => _TrafficLightModalState();
}

class _TrafficLightModalState extends State<TrafficLightModal> {
  late Map<String, TrafficLightState> _localStates;

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
                  'Control de Semáforos',
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
              'Selecciona el color para cada semáforo:',
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
                itemCount: 10,
                itemBuilder: (context, index) {
                  final semaphoreId = 'S${index + 1}';
                  final currentState =
                      _localStates[semaphoreId] ?? TrafficLightState.off;

                  return _buildSemaphoreControl(semaphoreId, currentState);
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
                      for (int i = 1; i <= 10; i++) {
                        _localStates['S$i'] = TrafficLightState.red;
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Todos Rojo'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      for (int i = 1; i <= 10; i++) {
                        _localStates['S$i'] = TrafficLightState.green;
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Todos Verde'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      for (int i = 1; i <= 10; i++) {
                        _localStates['S$i'] = TrafficLightState.off;
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Todos Apagados'),
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
                    widget.onTrafficLightChanged(id, state);
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

  Widget _buildSemaphoreControl(String id, TrafficLightState currentState) {
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
            id,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildColorButton(id, TrafficLightState.red, Colors.red),
              _buildColorButton(id, TrafficLightState.yellow, Colors.amber),
              _buildColorButton(id, TrafficLightState.green, Colors.green),
              _buildColorButton(id, TrafficLightState.off, Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorButton(String id, TrafficLightState state, Color color) {
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
      ),
    );
  }
}

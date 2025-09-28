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
              'Selecciona el color para cada grupo de semáforos:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            const Text(
              'SD: Semáforos de Dirección (S1, S2, S4, S5, S6, S8, S10)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Text(
              'SI: Semáforos de Intersección (S3, S7, S9)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Column(
              children: [
                _buildGroupControl(
                  'SD',
                  'Semáforos de Dirección',
                  _localStates['SD'] ?? TrafficLightState.off,
                ),
                const SizedBox(height: 20),
                _buildGroupControl(
                  'SI',
                  'Semáforos de Intersección',
                  _localStates['SI'] ?? TrafficLightState.off,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _localStates['SD'] = TrafficLightState.red;
                      _localStates['SI'] = TrafficLightState.red;
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
                      _localStates['SD'] = TrafficLightState.green;
                      _localStates['SI'] = TrafficLightState.green;
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
                      _localStates['SD'] = TrafficLightState.off;
                      _localStates['SI'] = TrafficLightState.off;
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

  Widget _buildGroupControl(
    String groupId,
    String groupName,
    TrafficLightState currentState,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Text(
            '$groupId - $groupName',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildColorButton(groupId, TrafficLightState.red, Colors.red),
              _buildColorButton(
                groupId,
                TrafficLightState.yellow,
                Colors.amber,
              ),
              _buildColorButton(groupId, TrafficLightState.green, Colors.green),
              _buildColorButton(groupId, TrafficLightState.off, Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorButton(
    String groupId,
    TrafficLightState state,
    Color color,
  ) {
    final isSelected = _localStates[groupId] == state;

    return GestureDetector(
      onTap: () {
        setState(() {
          _localStates[groupId] = state;
        });
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[400]!,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : null,
      ),
    );
  }
}

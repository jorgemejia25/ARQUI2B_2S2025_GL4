import 'package:flutter/material.dart';
import '../layouts/main_layout.dart';

/// Pantalla del mapa interactivo que simula las paradas en tiempo real.
///
/// Esta pantalla proporciona una vista interactiva del mapa donde los usuarios
/// pueden ver la ubicación de las paradas y el estado del tráfico en tiempo real.
class MapScreen extends StatefulWidget {
  /// Constructor de la pantalla del mapa.
  ///
  /// [key] - Clave opcional para el widget.
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Matriz que representa el estado de las calles (true = activa, false = inactiva)
  List<List<bool>> streetGrid = [];

  // Dimensiones del grid: 3 bloques horizontales x 2 bloques verticales
  final int gridRows = 5; // 2 calles horizontales + 3 filas de contenido
  final int gridCols = 7; // 4 calles verticales + 3 bloques de contenido

  @override
  void initState() {
    super.initState();
    _initializeGrid();
  }

  void _initializeGrid() {
    // Inicializar el grid con todas las calles inactivas
    streetGrid = List.generate(
      gridRows,
      (i) => List.generate(gridCols, (j) => false),
    );
  }

  void _toggleStreet(int row, int col) {
    setState(() {
      streetGrid[row][col] = !streetGrid[row][col];
    });
  }

  void _activateAllStreets() {
    setState(() {
      for (int i = 0; i < gridRows; i++) {
        for (int j = 0; j < gridCols; j++) {
          // Activar calles horizontales (primera, media y última fila)
          if (i == 0 || i == 2 || i == gridRows - 1) {
            streetGrid[i][j] = true;
          }
          // Activar calles verticales (columnas pares)
          if (j % 2 == 0) {
            streetGrid[i][j] = true;
          }
        }
      }
    });
  }

  void _clearAllStreets() {
    setState(() {
      _initializeGrid();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Mapa Interactivo',
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Controles
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _activateAllStreets,
                  icon: const Icon(Icons.map),
                  label: const Text('Activar Calles'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _clearAllStreets,
                  icon: const Icon(Icons.clear),
                  label: const Text('Limpiar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Mapa interactivo
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF1E3A8A), width: 3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridCols,
                      childAspectRatio: 1,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    itemCount: gridRows * gridCols,
                    itemBuilder: (context, index) {
                      final row = index ~/ gridCols;
                      final col = index % gridCols;

                      // Determinar si es calle o zona ocupada
                      final isHorizontalStreet =
                          row == 0 || row == 2 || row == gridRows - 1;
                      final isVerticalStreet = col % 2 == 0;
                      final isStreet = isHorizontalStreet || isVerticalStreet;
                      final isActive = streetGrid[row][col];

                      if (isStreet) {
                        return GestureDetector(
                          onTap: () => _toggleStreet(row, col),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(
                                      0xFF10B981,
                                    ) // Verde para calles activas
                                  : const Color(
                                      0xFFE5E7EB,
                                    ), // Gris para calles inactivas
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isActive
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFD1D5DB),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                isHorizontalStreet
                                    ? Icons.horizontal_rule
                                    : Icons.vertical_align_center,
                                color: isActive
                                    ? Colors.white
                                    : const Color(0xFF6B7280),
                                size: 24,
                              ),
                            ),
                          ),
                        );
                      } else {
                        // Zonas ocupadas (bloques de edificios)
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFFE5E7EB),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_city,
                                  color: const Color(0xFF9CA3AF),
                                  size: 20,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Zona ${((row - 1) ~/ 2 * 3 + (col ~/ 2)).toString()}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF9CA3AF),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

          
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../layouts/modern_layout.dart';
import '../models/blacklist_event.dart';
import '../models/blacklist_stats.dart';
import '../services/websocket_blacklist.dart';
import '../widgets/blacklist_event_card.dart';
import '../widgets/blacklist_stats_card.dart';
import '../config/app_theme.dart';

class BlacklistScreen extends StatefulWidget {
  const BlacklistScreen({super.key});

  @override
  State<BlacklistScreen> createState() => _BlacklistScreenState();
}

class _BlacklistScreenState extends State<BlacklistScreen> {
  final _ws = WebSocketBlacklistService.instance;
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  List<BlacklistEvent> _events = [];
  List<BlacklistStats> _stats = [];
  bool _isLoading = false;
  bool _isLoadingStats = false;
  bool _hasMoreData = true;
  int _currentOffset = 0;
  String? _personFilter;
  bool _connecting = false;
  bool _showStats = false;

  @override
  void initState() {
    super.initState();

    // Conectar WebSocket si no está conectado
    if (!_ws.isConnected && !_connecting) {
      _connecting = true;
      _ws
          .connect()
          .catchError((e) => _showSnack('Error de conexión: $e'))
          .whenComplete(() => _connecting = false);
    }

    // Configurar callbacks del WebSocket
    _ws.onEvent = _onNewEvent;
    _ws.onError = _showSnack;

    // Configurar scroll listener para paginación
    _scrollController.addListener(_onScroll);

    // Cargar eventos iniciales
    _loadInitialEvents();

    // Cargar estadísticas
    _loadStats();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onNewEvent(BlacklistEvent event) {
    setState(() {
      // Insertar al inicio de la lista
      _events.insert(0, event);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreEvents();
    }
  }

  Future<void> _loadInitialEvents() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _currentOffset = 0;
      _events.clear();
      _hasMoreData = true;
    });

    try {
      // Limpiar cache antes de cargar datos frescos
      _ws.clearCache();

      final response = await _ws.fetchHistoricalEvents(
        limit: 50,
        offset: 0,
        personFilter: _personFilter,
      );

      print('[BlacklistScreen] Loaded ${response.events.length} events');
      setState(() {
        _events = response.events;
        _hasMoreData = response.hasMorePages;
        _currentOffset = 50;
      });
    } catch (e) {
      _showSnack('Error cargando eventos: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreEvents() async {
    if (_isLoading || !_hasMoreData) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _ws.fetchHistoricalEvents(
        limit: 50,
        offset: _currentOffset,
        personFilter: _personFilter,
      );

      setState(() {
        _events.addAll(response.events);
        _hasMoreData = response.hasMorePages;
        _currentOffset += 50;
      });
    } catch (e) {
      _showSnack('Error cargando más eventos: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _searchEvents() {
    _personFilter = _searchController.text.trim().isEmpty
        ? null
        : _searchController.text.trim();
    _loadInitialEvents();
  }

  void _clearSearch() {
    _searchController.clear();
    _personFilter = null;
    _loadInitialEvents();
  }

  /// Cargar estadísticas
  Future<void> _loadStats() async {
    if (_isLoadingStats) return;

    setState(() {
      _isLoadingStats = true;
    });

    try {
      final stats = await _ws.fetchTopDetections(limit: 10);
      setState(() {
        _stats = stats;
      });
      print('[BlacklistScreen] Loaded ${stats.length} stats');
    } catch (e) {
      print('[BlacklistScreen] Error loading stats: $e');
    } finally {
      setState(() {
        _isLoadingStats = false;
      });
    }
  }

  /// Método específico para refresh con mejor manejo de errores
  Future<void> _refreshEvents() async {
    try {
      print('[BlacklistScreen] Starting refresh...');

      // Limpiar cache y reconectar si es necesario
      _ws.clearCache();

      if (!_ws.isConnected) {
        print('[BlacklistScreen] WebSocket not connected, reconnecting...');
        await _ws.reconnect();
      }

      await _loadInitialEvents();
      await _loadStats(); // También refrescar estadísticas
      print('[BlacklistScreen] Refresh completed');
    } catch (e) {
      print('[BlacklistScreen] Refresh error: $e');
      _showSnack('Error actualizando eventos: $e');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade600),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ModernLayout(
      title: 'Lista Negra',
      currentRoute: '/blacklist',
      child: Column(
        children: [
          // Barra de búsqueda
          _buildSearchBar(),

          // Indicador de conexión
          _buildConnectionStatus(),

          // Toggle para estadísticas/eventos
          _buildViewToggle(),

          // Contenido dinámico: estadísticas o eventos
          Expanded(child: _showStats ? _buildStatsList() : _buildEventsList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          // Campo de búsqueda simple
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryPurple.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Buscar persona...',
                  hintStyle: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppTheme.primaryPurple,
                    size: 18,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: AppTheme.primaryPurple,
                            size: 18,
                          ),
                          onPressed: _clearSearch,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  setState(() {}); // Para actualizar el ícono de clear
                },
                onSubmitted: (_) => _searchEvents(),
              ),
            ),
          ),

          // Botón de búsqueda compacto
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.purpleGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _searchEvents,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Icon(
                    Icons.search_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _ws.isConnected
              ? AppTheme.neonGreen.withOpacity(0.2)
              : AppTheme.error.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _ws.isConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
            size: 12,
            color: _ws.isConnected ? AppTheme.neonGreen : AppTheme.error,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _ws.isConnected ? 'Conectado' : 'Desconectado',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _ws.isConnected ? AppTheme.neonGreen : AppTheme.error,
              ),
            ),
          ),
          if (_personFilter != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: AppTheme.purpleGradient,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_personFilter',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 2),
                  GestureDetector(
                    onTap: _clearSearch,
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.primaryPurple.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              label: 'Eventos',
              icon: Icons.list_rounded,
              isSelected: !_showStats,
              onTap: () => setState(() => _showStats = false),
            ),
          ),
          Expanded(
            child: _buildToggleButton(
              label: 'Estadísticas',
              icon: Icons.bar_chart_rounded,
              isSelected: _showStats,
              onTap: () => setState(() => _showStats = true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected ? AppTheme.purpleGradient : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    if (_isLoading && _events.isEmpty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.backgroundCard, AppTheme.backgroundElevated],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryPurple.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryPurple,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Cargando eventos...',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Conectando con el servidor',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_events.isEmpty && !_isLoading) {
      return Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.backgroundCard, AppTheme.backgroundElevated],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryPurple.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.person_off_rounded,
                size: 64,
                color: AppTheme.primaryPurple,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _personFilter != null
                  ? 'No se encontraron eventos'
                  : 'Lista Negra Vacía',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _personFilter != null
                  ? 'No hay detecciones para "$_personFilter"'
                  : 'No hay eventos de personas no autorizadas',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshEvents,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _events.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _events.length) {
            // Indicador de carga al final
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryPurple.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryPurple,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Cargando más eventos...',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final event = _events[index];
          return BlacklistEventCard(
            event: event,
            onTap: () => _showEventDetails(event),
          );
        },
      ),
    );
  }

  void _showEventDetails(BlacklistEvent event) {
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
                        Icons.person_off_rounded,
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
                            'Evento de Lista Negra',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            event.personName,
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

              // Contenido
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildDetailRow('Confianza:', event.confidencePercentage),
                    _buildDetailRow(
                      'Distancia:',
                      event.distance.toStringAsFixed(3),
                    ),
                    _buildDetailRow(
                      'Cámara:',
                      event.cameraLocation ?? 'No especificada',
                    ),
                    _buildDetailRow(
                      'Fecha y Hora:',
                      event.formattedTimestampWithRelative,
                    ),
                  ],
                ),
              ),

              // Botón de cerrar
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundElevated.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryPurple,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsList() {
    if (_isLoadingStats && _stats.isEmpty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.backgroundCard, AppTheme.backgroundElevated],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryPurple.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryPurple,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Cargando estadísticas...',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_stats.isEmpty && !_isLoadingStats) {
      return Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.backgroundCard, AppTheme.backgroundElevated],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryPurple.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.bar_chart_rounded,
                size: 64,
                color: AppTheme.primaryPurple,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No hay estadísticas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No hay datos suficientes para mostrar estadísticas',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        itemCount: _stats.length,
        itemBuilder: (context, index) {
          final stat = _stats[index];
          return BlacklistStatsCard(
            personName: stat.personName,
            totalDetections: stat.totalDetections,
            avgConfidence: stat.avgConfidence,
            lastDetection: stat.formattedLastDetection,
            rank: index + 1,
            onTap: () {
              // Cambiar a eventos y filtrar por esta persona
              setState(() {
                _showStats = false;
                _personFilter = stat.personName;
                _searchController.text = stat.personName;
              });
              _loadInitialEvents();
            },
          );
        },
      ),
    );
  }
}

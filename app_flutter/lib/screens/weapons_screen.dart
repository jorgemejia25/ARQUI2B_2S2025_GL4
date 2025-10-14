import 'package:flutter/material.dart';
import '../layouts/modern_layout.dart';
import '../config/app_theme.dart';
import '../services/weapon_api_service.dart';
import '../models/weapon_event.dart';
import '../models/weapon_count.dart';
import '../widgets/weapon_event_card.dart';
import '../widgets/weapon_top_item.dart';
import '../utils/weapon_utils.dart';
import '../services/websocket_weapons.dart';

class WeaponsScreen extends StatefulWidget {
  const WeaponsScreen({super.key});

  @override
  State<WeaponsScreen> createState() => _WeaponsScreenState();
}

class _WeaponsScreenState extends State<WeaponsScreen> {
  final _api = WeaponApiService();
  final _ws = WebSocketWeaponsService.instance;
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  List<WeaponEvent> _events = [];
  List<WeaponCount> _top = [];
  bool _isLoading = false;
  bool _isLoadingTop = false;
  bool _hasMoreData = true;
  int _currentOffset = 0;
  String? _weaponFilterEn; // server expects English names
  bool _showTop = false;
  bool _wsConnected = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
    _loadTop();

    // Registrar callbacks ANTES de conectar para evitar condiciones de carrera
    _ws.onEvent = (WeaponEvent event) {
      if (!mounted) return;
      // Insertar en tiempo real si coincide el filtro actual (si existe)
      if (_weaponFilterEn == null || _weaponFilterEn == event.nameEn) {
        setState(() {
          _events.insert(0, event);
        });
      }
    };
    // Estado de conexión
    _ws.onConnected = () {
      if (!mounted) return;
      setState(() => _wsConnected = true);
    };
    _ws.onDisconnected = () {
      if (!mounted) return;
      setState(() => _wsConnected = false);
    };
    _ws.onError = (msg) {
      if (!mounted) return;
      _showSnack('WS armas: $msg');
    };
    // Conectar WebSocket para actualizaciones en tiempo real
    _ws.connect().catchError((e) {
      if (!mounted) return;
      _showSnack('WS armas: $e');
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    // Limpiar callbacks antes de desconectar para evitar llamadas a un widget desmontado
    _ws.onEvent = null;
    _ws.onConnected = null;
    _ws.onDisconnected = null;
    _ws.onError = null;
    _ws.disconnect();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _events.clear();
      _currentOffset = 0;
      _hasMoreData = true;
    });

    try {
      final events = await _api.fetchWeaponDetections(
        limit: 50,
        offset: 0,
        nameFilterEn: _weaponFilterEn,
      );
      setState(() {
        _events = events; // assumed API returns latest first
        _currentOffset = 50;
        _hasMoreData = events.length == 50;
      });
    } catch (e) {
      _showSnack('Error cargando armas detectadas: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMoreData) return;
    setState(() => _isLoading = true);
    try {
      final events = await _api.fetchWeaponDetections(
        limit: 50,
        offset: _currentOffset,
        nameFilterEn: _weaponFilterEn,
      );
      setState(() {
        _events.addAll(events);
        _currentOffset += 50;
        _hasMoreData = events.length == 50;
      });
    } catch (e) {
      _showSnack('Error cargando más armas: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTop() async {
    if (_isLoadingTop) return;
    setState(() => _isLoadingTop = true);
    try {
      final top = await _api.fetchTopWeapons(limit: 3);
      setState(() => _top = top);
    } catch (e) {
      _showSnack('Error cargando top de armas: $e');
    } finally {
      setState(() => _isLoadingTop = false);
    }
  }

  void _search() {
    final mapped = WeaponUtils.toEnglishIfSpanish(_searchController.text);
    _weaponFilterEn = mapped ?? _searchController.text.trim();
    if (_weaponFilterEn!.isEmpty) _weaponFilterEn = null;
    _loadInitial();
  }

  void _clearSearch() {
    _searchController.clear();
    _weaponFilterEn = null;
    _loadInitial();
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
      title: 'Armas Blancas',
      currentRoute: '/weapons',
      child: Column(
        children: [
          _buildSearchBar(),
          _buildConnectionStatus(),
          _buildToggle(),
          Expanded(
            child: _showTop ? _buildTopList() : _buildEventsList(),
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
          color: _wsConnected
              ? AppTheme.neonGreen.withOpacity(0.2)
              : AppTheme.error.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _wsConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
            size: 12,
            color: _wsConnected ? AppTheme.neonGreen : AppTheme.error,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _wsConnected ? 'Conectado' : 'Desconectado',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _wsConnected ? AppTheme.neonGreen : AppTheme.error,
              ),
            ),
          ),
          if (_weaponFilterEn != null)
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
                    WeaponUtils.toSpanish(_weaponFilterEn!),
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

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
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
                  hintText: 'Buscar arma blanca (Cuchillo, Rasuradora, Tijeras)...',
                  hintStyle: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, color: AppTheme.primaryPurple, size: 18),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, color: AppTheme.primaryPurple, size: 18),
                          onPressed: _clearSearch,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _search(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(gradient: AppTheme.purpleGradient, borderRadius: BorderRadius.circular(10)),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _search,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Icon(Icons.search_rounded, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _toggleButton(label: 'Detectadas', icon: Icons.list_rounded, selected: !_showTop, onTap: () {
              setState(() => _showTop = false);
            }),
          ),
          Expanded(
            child: _toggleButton(label: 'Top', icon: Icons.bar_chart_rounded, selected: _showTop, onTap: () {
              setState(() => _showTop = true);
              _loadTop();
            }),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton({required String label, required IconData icon, required bool selected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryPurple.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? AppTheme.primaryPurple : AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: selected ? AppTheme.primaryPurple : AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    if (_isLoading && _events.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_events.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/knife.jpg', width: 64, height: 64, fit: BoxFit.contain),
            const SizedBox(height: 8),
            Text('No hay armas detectadas', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        await _loadInitial();
        await _loadTop();
      },
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _events.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _events.length) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return WeaponEventCard(event: _events[index]);
        },
      ),
    );
  }

  Widget _buildTopList() {
    if (_isLoadingTop && _top.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_top.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/knife.jpg', width: 64, height: 64, fit: BoxFit.contain),
            const SizedBox(height: 8),
            Text('Sin datos de top', style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadTop();
      },
      child: ListView.builder(
        itemCount: _top.length,
        itemBuilder: (context, index) {
          return WeaponTopItem(item: _top[index]);
        },
      ),
    );
  }
}

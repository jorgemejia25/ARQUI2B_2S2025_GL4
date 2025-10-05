import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'dashboard_filters.dart';

/// Widget de filtros integrado que se muestra como barra deslizable
class IntegratedFiltersBar extends StatefulWidget {
  final DashboardFilters filters;
  final Function(DashboardFilters) onFiltersChanged;
  final VoidCallback? onToggleAdvanced;

  const IntegratedFiltersBar({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
    this.onToggleAdvanced,
  });

  @override
  State<IntegratedFiltersBar> createState() => _IntegratedFiltersBarState();
}

class _IntegratedFiltersBarState extends State<IntegratedFiltersBar> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: _isExpanded ? 200 : 60,
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.greyMedium.withOpacity(0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barra principal de filtros
          _buildMainFilterBar(),

          // Panel expandible con filtros avanzados
          if (_isExpanded) _buildAdvancedFilters(),
        ],
      ),
    );
  }

  Widget _buildMainFilterBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
      child: Row(
        children: [
          // Botón de filtros activos
          _buildActiveFiltersButton(),

          const SizedBox(width: AppTheme.spaceMedium),

          // Filtros rápidos
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickFilterChip('Hoy', _isTodayFilter()),
                  _buildQuickFilterChip('7 días', _isWeekFilter()),
                  _buildQuickFilterChip('30 días', _isMonthFilter()),
                  _buildQuickFilterChip('Gas', _hasEventTypeFilter('GAS')),
                  _buildQuickFilterChip(
                    'Sísmico',
                    _hasEventTypeFilter('SISMO'),
                  ),
                  _buildQuickFilterChip(
                    'Tráfico',
                    _hasEventTypeFilter('INFRACCION'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: AppTheme.spaceMedium),

          // Botón de filtros avanzados
          _buildAdvancedToggleButton(),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersButton() {
    final activeCount = _getActiveFiltersCount();

    return GestureDetector(
      onTap: () {
        if (activeCount > 0) {
          _clearAllFilters();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMedium,
          vertical: AppTheme.spaceSmall,
        ),
        decoration: BoxDecoration(
          color: activeCount > 0
              ? AppTheme.primaryPurple.withOpacity(0.1)
              : AppTheme.backgroundElevated.withOpacity(0.3),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(
            color: activeCount > 0
                ? AppTheme.primaryPurple.withOpacity(0.3)
                : AppTheme.greyMedium.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list_rounded,
              size: 16,
              color: activeCount > 0
                  ? AppTheme.primaryPurple
                  : AppTheme.textSecondary,
            ),
            const SizedBox(width: AppTheme.spaceXSmall),
            Text(
              activeCount > 0 ? '$activeCount filtros' : 'Filtros',
              style: AppTheme.bodySmall.copyWith(
                color: activeCount > 0
                    ? AppTheme.primaryPurple
                    : AppTheme.textSecondary,
                fontWeight: activeCount > 0
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
            if (activeCount > 0) ...[
              const SizedBox(width: AppTheme.spaceXSmall),
              Icon(
                Icons.close_rounded,
                size: 14,
                color: AppTheme.primaryPurple,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilterChip(String label, bool isActive) {
    return GestureDetector(
      onTap: () => _toggleQuickFilter(label),
      child: Container(
        margin: const EdgeInsets.only(right: AppTheme.spaceSmall),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMedium,
          vertical: AppTheme.spaceSmall,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryPurple.withOpacity(0.1)
              : AppTheme.backgroundElevated.withOpacity(0.3),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(
            color: isActive
                ? AppTheme.primaryPurple.withOpacity(0.3)
                : AppTheme.greyMedium.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: isActive ? AppTheme.primaryPurple : AppTheme.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedToggleButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceSmall),
        decoration: BoxDecoration(
          color: AppTheme.backgroundElevated.withOpacity(0.3),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(
            color: AppTheme.greyMedium.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.tune_rounded,
          size: 20,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.backgroundElevated.withOpacity(0.3),
        border: Border(
          top: BorderSide(
            color: AppTheme.greyMedium.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Filtros de fecha
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'Desde',
                  value: widget.filters.startDate,
                  onTap: () => _selectDate(true),
                ),
              ),
              const SizedBox(width: AppTheme.spaceMedium),
              Expanded(
                child: _buildDateField(
                  label: 'Hasta',
                  value: widget.filters.endDate,
                  onTap: () => _selectDate(false),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spaceMedium),

          // Tipos de eventos
          _buildEventTypesRow(),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceSmall),
        decoration: BoxDecoration(
          color: AppTheme.backgroundCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(
            color: AppTheme.greyMedium.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: AppTheme.primaryPurple,
            ),
            const SizedBox(width: AppTheme.spaceXSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTheme.caption.copyWith(
                      color: AppTheme.textTertiary,
                    ),
                  ),
                  Text(
                    value != null ? '${value.day}/${value.month}' : 'Sin fecha',
                    style: AppTheme.bodySmall.copyWith(
                      color: value != null
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTypesRow() {
    final types = [
      ('GAS', 'Gas', Icons.air_rounded, AppTheme.neonGreen),
      ('SISMO', 'Sísmico', Icons.vibration_rounded, AppTheme.neonYellow),
      (
        'INFRACCION',
        'Tráfico',
        Icons.directions_car_rounded,
        AppTheme.neonOrange,
      ),
      ('PANICO', 'Pánico', Icons.warning_amber_rounded, AppTheme.neonPink),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: types.map((type) {
          final isSelected = widget.filters.eventTypes.contains(type.$1);
          return GestureDetector(
            onTap: () => _toggleEventType(type.$1),
            child: Container(
              margin: const EdgeInsets.only(right: AppTheme.spaceSmall),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceSmall,
                vertical: AppTheme.spaceXSmall,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? type.$4.withOpacity(0.1)
                    : AppTheme.backgroundCard,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(
                  color: isSelected
                      ? type.$4.withOpacity(0.3)
                      : AppTheme.greyMedium.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    type.$3,
                    size: 14,
                    color: isSelected ? type.$4 : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: AppTheme.spaceXSmall),
                  Text(
                    type.$2,
                    style: AppTheme.caption.copyWith(
                      color: isSelected ? type.$4 : AppTheme.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Métodos de utilidad
  int _getActiveFiltersCount() {
    int count = 0;
    if (widget.filters.startDate != null) count++;
    if (widget.filters.endDate != null) count++;
    if (widget.filters.eventTypes.isNotEmpty) count++;
    if (widget.filters.severityMin != null) count++;
    if (widget.filters.severityMax != null) count++;
    return count;
  }

  bool _isTodayFilter() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return widget.filters.startDate == today && widget.filters.endDate == null;
  }

  bool _isWeekFilter() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return widget.filters.startDate == weekAgo &&
        widget.filters.endDate == null;
  }

  bool _isMonthFilter() {
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));
    return widget.filters.startDate == monthAgo &&
        widget.filters.endDate == null;
  }

  bool _hasEventTypeFilter(String type) {
    return widget.filters.eventTypes.contains(type);
  }

  void _toggleQuickFilter(String label) {
    final newFilters = DashboardFilters(
      startDate: widget.filters.startDate,
      endDate: widget.filters.endDate,
      eventTypes: List.from(widget.filters.eventTypes),
      severityMin: widget.filters.severityMin,
      severityMax: widget.filters.severityMax,
      groupBy: widget.filters.groupBy,
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (label) {
      case 'Hoy':
        newFilters.startDate = today;
        newFilters.endDate = null;
        break;
      case '7 días':
        newFilters.startDate = now.subtract(const Duration(days: 7));
        newFilters.endDate = null;
        break;
      case '30 días':
        newFilters.startDate = now.subtract(const Duration(days: 30));
        newFilters.endDate = null;
        break;
    }

    widget.onFiltersChanged(newFilters);
  }

  void _toggleEventType(String type) {
    final newFilters = DashboardFilters(
      startDate: widget.filters.startDate,
      endDate: widget.filters.endDate,
      eventTypes: List.from(widget.filters.eventTypes),
      severityMin: widget.filters.severityMin,
      severityMax: widget.filters.severityMax,
      groupBy: widget.filters.groupBy,
    );

    if (newFilters.eventTypes.contains(type)) {
      newFilters.eventTypes.remove(type);
    } else {
      newFilters.eventTypes.add(type);
    }

    widget.onFiltersChanged(newFilters);
  }

  void _clearAllFilters() {
    final newFilters = DashboardFilters();
    widget.onFiltersChanged(newFilters);
  }

  Future<void> _selectDate(bool isStartDate) async {
    final initialDate = isStartDate
        ? widget.filters.startDate ?? DateTime.now()
        : widget.filters.endDate ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primaryPurple,
              onPrimary: Colors.white,
              surface: AppTheme.backgroundCard,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final newFilters = DashboardFilters(
        startDate: isStartDate ? picked : widget.filters.startDate,
        endDate: isStartDate ? widget.filters.endDate : picked,
        eventTypes: List.from(widget.filters.eventTypes),
        severityMin: widget.filters.severityMin,
        severityMax: widget.filters.severityMax,
        groupBy: widget.filters.groupBy,
      );

      widget.onFiltersChanged(newFilters);
    }
  }
}






import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Modelo de filtros para el dashboard
class DashboardFilters {
  DateTime? startDate;
  DateTime? endDate;
  List<String> eventTypes;
  int? severityMin;
  int? severityMax;
  String groupBy;

  DashboardFilters({
    this.startDate,
    this.endDate,
    this.eventTypes = const [],
    this.severityMin,
    this.severityMax,
    this.groupBy = 'hour',
  });

  bool get hasActiveFilters =>
      startDate != null ||
      endDate != null ||
      eventTypes.isNotEmpty ||
      severityMin != null ||
      severityMax != null;

  void clear() {
    startDate = null;
    endDate = null;
    eventTypes = [];
    severityMin = null;
    severityMax = null;
    groupBy = 'hour';
  }

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};

    if (startDate != null) {
      params['start_date'] = startDate!.toIso8601String().split('T')[0];
    }

    if (endDate != null) {
      params['end_date'] = endDate!.toIso8601String().split('T')[0];
    }

    if (eventTypes.isNotEmpty) {
      params['event_types'] = eventTypes.join(',');
    }

    if (severityMin != null) {
      params['severity_min'] = severityMin.toString();
    }

    if (severityMax != null) {
      params['severity_max'] = severityMax.toString();
    }

    params['group_by'] = groupBy;

    return params;
  }
}

/// Widget de panel de filtros avanzados
class DashboardFiltersPanel extends StatefulWidget {
  final DashboardFilters filters;
  final Function(DashboardFilters) onFiltersChanged;
  final VoidCallback? onClose;

  const DashboardFiltersPanel({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
    this.onClose,
  });

  @override
  State<DashboardFiltersPanel> createState() => _DashboardFiltersPanelState();
}

class _DashboardFiltersPanelState extends State<DashboardFiltersPanel> {
  late DashboardFilters _localFilters;

  @override
  void initState() {
    super.initState();
    _localFilters = DashboardFilters(
      startDate: widget.filters.startDate,
      endDate: widget.filters.endDate,
      eventTypes: List.from(widget.filters.eventTypes),
      severityMin: widget.filters.severityMin,
      severityMax: widget.filters.severityMax,
      groupBy: widget.filters.groupBy,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.greyMedium.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceSmall),
                decoration: BoxDecoration(
                  gradient: AppTheme.purpleGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: const Icon(
                  Icons.filter_list_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMedium),
              Text(
                'Filtros Avanzados',
                style: AppTheme.headingMedium.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                color: AppTheme.textSecondary,
                onPressed: widget.onClose,
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spaceLarge),

          // Filtros de fecha
          _buildDateFilters(),

          const SizedBox(height: AppTheme.spaceLarge),

          // Tipos de eventos
          _buildEventTypesFilter(),

          const SizedBox(height: AppTheme.spaceLarge),

          // Severidad
          _buildSeverityFilter(),

          const SizedBox(height: AppTheme.spaceLarge),

          // Agrupación
          _buildGroupByFilter(),

          const SizedBox(height: AppTheme.spaceXLarge),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _localFilters.clear();
                    });
                    widget.onFiltersChanged(_localFilters);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: BorderSide(
                      color: AppTheme.greyMedium.withOpacity(0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                  child: const Text('Limpiar'),
                ),
              ),
              const SizedBox(width: AppTheme.spaceMedium),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onFiltersChanged(_localFilters);
                    widget.onClose?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                  ),
                  child: const Text('Aplicar Filtros'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rango de Fechas',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                label: 'Desde',
                value: _localFilters.startDate,
                onTap: () => _selectDate(context, true),
              ),
            ),
            const SizedBox(width: AppTheme.spaceMedium),
            Expanded(
              child: _buildDateField(
                label: 'Hasta',
                value: _localFilters.endDate,
                onTap: () => _selectDate(context, false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        decoration: BoxDecoration(
          color: AppTheme.backgroundElevated.withOpacity(0.3),
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
              size: 16,
              color: AppTheme.primaryPurple,
            ),
            const SizedBox(width: AppTheme.spaceSmall),
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
                    value != null
                        ? '${value.day}/${value.month}/${value.year}'
                        : 'Sin seleccionar',
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

  Widget _buildEventTypesFilter() {
    final types = [
      (
        'INFRACCION',
        'Tráfico',
        Icons.directions_car_rounded,
        AppTheme.neonOrange,
      ),
      ('PANICO', 'Pánico', Icons.warning_amber_rounded, AppTheme.neonPink),
      ('SISMO', 'Sísmico', Icons.vibration_rounded, AppTheme.neonYellow),
      ('GAS', 'Gas', Icons.air_rounded, AppTheme.neonGreen),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipos de Eventos',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        Wrap(
          spacing: AppTheme.spaceSmall,
          runSpacing: AppTheme.spaceSmall,
          children: types.map((type) {
            final isSelected = _localFilters.eventTypes.contains(type.$1);
            return FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    type.$3,
                    size: 16,
                    color: isSelected ? Colors.white : type.$4,
                  ),
                  const SizedBox(width: AppTheme.spaceXSmall),
                  Text(type.$2),
                ],
              ),
              backgroundColor: AppTheme.backgroundElevated.withOpacity(0.3),
              selectedColor: type.$4,
              checkmarkColor: Colors.white,
              labelStyle: AppTheme.bodySmall.copyWith(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected
                    ? type.$4
                    : AppTheme.greyMedium.withOpacity(0.3),
                width: 1,
              ),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _localFilters.eventTypes.add(type.$1);
                  } else {
                    _localFilters.eventTypes.remove(type.$1);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSeverityFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rango de Severidad',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        Row(
          children: [
            Expanded(
              child: _buildSeverityDropdown(
                label: 'Mínima',
                value: _localFilters.severityMin,
                onChanged: (value) {
                  setState(() {
                    _localFilters.severityMin = value;
                  });
                },
              ),
            ),
            const SizedBox(width: AppTheme.spaceMedium),
            Expanded(
              child: _buildSeverityDropdown(
                label: 'Máxima',
                value: _localFilters.severityMax,
                onChanged: (value) {
                  setState(() {
                    _localFilters.severityMax = value;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSeverityDropdown({
    required String label,
    required int? value,
    required Function(int?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMedium,
        vertical: AppTheme.spaceSmall,
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundElevated.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: AppTheme.greyMedium.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: value,
          hint: Text(
            label,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
          ),
          isExpanded: true,
          dropdownColor: AppTheme.backgroundCard,
          icon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryPurple),
          style: AppTheme.bodySmall.copyWith(color: AppTheme.textPrimary),
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text('Sin filtro', style: AppTheme.bodySmall),
            ),
            ...List.generate(4, (index) {
              final severity = index + 1;
              return DropdownMenuItem<int?>(
                value: severity,
                child: Text('Nivel $severity'),
              );
            }),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildGroupByFilter() {
    final options = [
      ('hour', 'Hora', Icons.access_time_rounded),
      ('day', 'Día', Icons.calendar_today_rounded),
      ('week', 'Semana', Icons.date_range_rounded),
      ('month', 'Mes', Icons.calendar_month_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Agrupar Por',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
        Wrap(
          spacing: AppTheme.spaceSmall,
          runSpacing: AppTheme.spaceSmall,
          children: options.map((option) {
            final isSelected = _localFilters.groupBy == option.$1;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    option.$3,
                    size: 16,
                    color: isSelected ? Colors.white : AppTheme.primaryPurple,
                  ),
                  const SizedBox(width: AppTheme.spaceXSmall),
                  Text(option.$2),
                ],
              ),
              selected: isSelected,
              backgroundColor: AppTheme.backgroundElevated.withOpacity(0.3),
              selectedColor: AppTheme.primaryPurple,
              labelStyle: AppTheme.bodySmall.copyWith(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected
                    ? AppTheme.primaryPurple
                    : AppTheme.greyMedium.withOpacity(0.3),
                width: 1,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _localFilters.groupBy = option.$1;
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final initialDate = isStartDate
        ? _localFilters.startDate ?? DateTime.now()
        : _localFilters.endDate ?? DateTime.now();

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
      setState(() {
        if (isStartDate) {
          _localFilters.startDate = picked;
        } else {
          _localFilters.endDate = picked;
        }
      });
    }
  }
}

















import 'package:flutter/material.dart';

/// Modelo que representa una parada de bus en el sistema de tráfico.
class BusStop {
  final String id;
  BusStopState state;
  final String svgId;
  final String displayName;
  final String location;

  BusStop({
    required this.id,
    this.state = BusStopState.inactive,
    required this.svgId,
    required this.displayName,
    required this.location,
  });

  Color get color {
    switch (state) {
      case BusStopState.active:
        return Colors.green;
      case BusStopState.inactive:
        return Colors.grey;
      case BusStopState.busy:
        return Colors.red;
      case BusStopState.waiting:
        return Colors.amber;
    }
  }

  String get hexColor {
    switch (state) {
      case BusStopState.active:
        return '#00FF00'; // Verde brillante para Transmetro
      case BusStopState.inactive:
        return '#808080'; // Gris para inactiva
      case BusStopState.busy:
        return '#0080FF'; // Azul para Transurbano
      case BusStopState.waiting:
        return '#FFFF00'; // Amarillo brillante para esperando
    }
  }

  void changeState(BusStopState newState) {
    state = newState;
  }

  void toggleActive() {
    if (state == BusStopState.active) {
      state = BusStopState.inactive;
    } else {
      state = BusStopState.active;
    }
  }

  void setBusy() {
    state = BusStopState.busy;
  }

  void setWaiting() {
    state = BusStopState.waiting;
  }

  void reset() {
    state = BusStopState.inactive;
  }
}

/// Enum que define los tipos de paradas de bus disponibles.
enum BusStopType {
  /// Sistema de transporte Transmetro.
  transmetro,

  /// Sistema de transporte Transurbano.
  transurbano,
}

/// Extensión para obtener el nombre legible del tipo de parada.
extension BusStopTypeExtension on BusStopType {
  /// Obtiene el nombre legible del tipo de parada.
  String get displayName {
    switch (this) {
      case BusStopType.transmetro:
        return 'Transmetro';
      case BusStopType.transurbano:
        return 'Transurbano';
    }
  }
}

enum BusStopState {
  active, // Parada activa (verde)
  inactive, // Parada inactiva (gris)
  busy, // Parada ocupada (rojo)
  waiting, // Parada con espera (amarillo)
}

/// Extensión para obtener el nombre legible del estado de la parada
extension BusStopStateExtension on BusStopState {
  String get displayName {
    switch (this) {
      case BusStopState.active:
        return 'Activa';
      case BusStopState.inactive:
        return 'Inactiva';
      case BusStopState.busy:
        return 'Ocupada';
      case BusStopState.waiting:
        return 'Esperando';
    }
  }
}

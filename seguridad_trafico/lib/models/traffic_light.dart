import 'package:flutter/material.dart';

/// Modelo que representa un semáforo en el sistema de tráfico.
class TrafficLight {
  final String id;
  TrafficLightState state;
  final String svgId;

  TrafficLight({
    required this.id,
    this.state = TrafficLightState.off,
    required this.svgId,
  });

  Color get color {
    switch (state) {
      case TrafficLightState.red:
        return Colors.red;
      case TrafficLightState.yellow:
        return Colors.amber;
      case TrafficLightState.green:
        return Colors.green;
      case TrafficLightState.off:
        return Colors.grey;
    }
  }

  String get hexColor {
    switch (state) {
      case TrafficLightState.red:
        return '#FF0000';
      case TrafficLightState.yellow:
        return '#FFA500';
      case TrafficLightState.green:
        return '#00FF00';
      case TrafficLightState.off:
        return '#4A4A4A';
    }
  }

  void changeState(TrafficLightState newState) {
    state = newState;
  }

  void toggleState() {
    switch (state) {
      case TrafficLightState.red:
        state = TrafficLightState.green;
        break;
      case TrafficLightState.green:
        state = TrafficLightState.yellow;
        break;
      case TrafficLightState.yellow:
        state = TrafficLightState.red;
        break;
      case TrafficLightState.off:
        state = TrafficLightState.red;
        break;
    }
  }
}

/// Enum que define los estados posibles de un semáforo.
enum TrafficLightState { red, yellow, green, off }

/// Extensión para obtener el nombre legible del estado del semáforo.
extension TrafficLightStatusExtension on TrafficLightState {
  /// Obtiene el nombre legible del estado del semáforo.
  String get displayName {
    switch (this) {
      case TrafficLightState.red:
        return 'Rojo';
      case TrafficLightState.yellow:
        return 'Amarillo';
      case TrafficLightState.green:
        return 'Verde';
      case TrafficLightState.off:
        return 'Apagado';
    }
  }
}

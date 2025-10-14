class WeaponEvent {
  final int id;
  final DateTime ts;
  final String nameEn;
  final String nameEs;
  final double distance;
  final String? cameraLocation;

  WeaponEvent({
    required this.id,
    required this.ts,
    required this.nameEn,
    required this.nameEs,
    required this.distance,
    required this.cameraLocation,
  });

  factory WeaponEvent.fromJson(Map<String, dynamic> json) {
    // API weapon detections response schema fields: id, ts, name, distance, camera_location
    final tsValue = json['ts'];
    DateTime tsParsed;
    if (tsValue is String) {
      tsParsed = DateTime.tryParse(tsValue) ?? DateTime.now();
    } else if (tsValue is int) {
      tsParsed = DateTime.fromMillisecondsSinceEpoch(tsValue);
    } else {
      tsParsed = DateTime.now();
    }
    final nameEn = (json['name'] as String?) ?? '';
    return WeaponEvent(
      id: (json['id'] as num).toInt(),
      ts: tsParsed,
      nameEn: nameEn,
      nameEs: nameEn, // replace later with Spanish mapped name on UI
      distance: (json['distance'] as num).toDouble(),
      cameraLocation: json['camera_location'] as String?,
    );
  }
}
class WeaponCount {
  final int top;
  final String nameEn;
  final String nameEs;
  final int count;

  WeaponCount({
    required this.top,
    required this.nameEn,
    required this.nameEs,
    required this.count,
  });

  factory WeaponCount.fromJson(Map<String, dynamic> json, {required int index}) {
    // API weapon-counts returns: { name, count }
    final nameEn = (json['name'] as String?) ?? '';
    return WeaponCount(
      top: index + 1,
      nameEn: nameEn,
      nameEs: nameEn,
      count: (json['count'] as num).toInt(),
    );
  }
}
class WeaponUtils {
  static const Map<String, String> enToEs = {
    'knife': 'Cuchillo',
    'razor': 'Rasuradora',
    'scissors': 'Tijeras',
  };

  static String toSpanish(String nameEn) {
    final lower = nameEn.toLowerCase();
    return enToEs[lower] ?? nameEn;
  }

  static String assetFor(String nameEn) {
    final lower = nameEn.toLowerCase();
    switch (lower) {
      case 'knife':
        return 'assets/knife.jpg';
      case 'razor':
        return 'assets/rasuradora.jpg';
      case 'scissors':
        return 'assets/tijeras.jpg';
      default:
        return 'assets/knife.jpg';
    }
  }

  static String? toEnglishIfSpanish(String term) {
    final t = term.trim().toLowerCase();
    // Map Spanish search to English class names
    if (t == 'cuchillo') return 'knife';
    if (t == 'rasuradora' || t == 'afeitadora') return 'razor';
    if (t == 'tijeras' || t == 'tijera') return 'scissors';
    // If user typed English already, keep it
    if (['knife', 'razor', 'scissors'].contains(t)) return t;
    return null; // unknown mapping -> don't filter by name
  }
}
/// Utilidades para formateo de fechas
class DateFormatter {
  /// Formatear fecha y hora completa con segundos
  /// Formato: DD/MM/YYYY HH:MM:SS
  static String formatDateTimeWithSeconds(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute:$second';
  }

  /// Formatear fecha y hora con tiempo relativo
  /// Formato: DD/MM/YYYY HH:MM:SS (Hace Xs/m/h/d)
  static String formatDateTimeWithRelative(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    String relativeTime;
    if (diff.inMinutes < 1) {
      relativeTime = 'Hace ${diff.inSeconds}s';
    } else if (diff.inHours < 1) {
      relativeTime = 'Hace ${diff.inMinutes}m';
    } else if (diff.inDays < 1) {
      relativeTime = 'Hace ${diff.inHours}h';
    } else {
      relativeTime = 'Hace ${diff.inDays}d';
    }

    return '${formatDateTimeWithSeconds(dateTime)} ($relativeTime)';
  }

  /// Formatear solo fecha
  /// Formato: DD/MM/YYYY
  static String formatDate(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;

    return '$day/$month/$year';
  }

  /// Formatear solo hora
  /// Formato: HH:MM:SS
  static String formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');

    return '$hour:$minute:$second';
  }
}

/// Утилита для безопасного парсинга дат
class SafeDateParser {
  /// Безопасный парсинг даты с обработкой ошибок
  static DateTime parse(dynamic value, {DateTime? fallback}) {
    if (value == null) {
      return fallback ?? DateTime.now();
    }

    try {
      String dateStr = value.toString();

      // Исправляем некорректный год (025 -> 2025)
      // Паттерн: начинается с 0 и затем 2-3 цифры, затем дефис
      final yearFixRegex = RegExp(r'^0(\d{2,3})-');
      if (yearFixRegex.hasMatch(dateStr)) {
        dateStr = dateStr.replaceFirstMapped(
          yearFixRegex,
          (match) => '2${match.group(1)}-',
        );
      }

      return DateTime.parse(dateStr);
    } catch (e) {
      // Если парсинг не удался, возвращаем fallback
      return fallback ?? DateTime.now();
    }
  }

  /// Безопасный парсинг nullable даты
  static DateTime? tryParse(dynamic value) {
    if (value == null) return null;

    try {
      String dateStr = value.toString();

      // Исправляем некорректный год
      final yearFixRegex = RegExp(r'^0(\d{2,3})-');
      if (yearFixRegex.hasMatch(dateStr)) {
        dateStr = dateStr.replaceFirstMapped(
          yearFixRegex,
          (match) => '2${match.group(1)}-',
        );
      }

      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }
}






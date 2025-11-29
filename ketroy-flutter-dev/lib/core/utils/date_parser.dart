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

  /// Форматирует дату в релативный формат (например: "сейчас", "5 минут назад", "вчера")
  /// с поддержкой многоязычности
  static String formatRelativeTime(DateTime dateTime, dynamic l10n) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    // Если это будущее время - возвращаем как текущее
    if (difference.isNegative) {
      return l10n.timeNow;
    }

    // Секунды
    if (difference.inSeconds < 60) {
      return l10n.timeNow;
    }

    // Минуты
    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      if (minutes == 1) {
        return l10n.timeMinutesAgo(1);
      }
      return l10n.timeMinutesAgo(minutes);
    }

    // Часы
    if (difference.inHours < 24) {
      final hours = difference.inHours;
      if (hours == 1) {
        return l10n.timeHoursAgo(1);
      }
      return l10n.timeHoursAgo(hours);
    }

    // Вчера
    final yesterday = now.subtract(const Duration(days: 1));
    if (dateTime.year == yesterday.year &&
        dateTime.month == yesterday.month &&
        dateTime.day == yesterday.day) {
      return l10n.timeYesterday;
    }

    // Дни в этой неделе (последние 7 дней)
    if (difference.inDays < 7) {
      final weekday = dateTime.weekday;
      return l10n.timeWeekday(
        _getWeekdayName(weekday, l10n),
      );
    }

    // Недели
    if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      if (weeks == 1) {
        return l10n.timeWeeksAgo(1);
      }
      return l10n.timeWeeksAgo(weeks);
    }

    // Месяцы
    if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      if (months == 1) {
        return l10n.timeMonthsAgo(1);
      }
      return l10n.timeMonthsAgo(months);
    }

    // Годы
    final years = (difference.inDays / 365).floor();
    if (years == 1) {
      return l10n.timeYearsAgo(1);
    }
    return l10n.timeYearsAgo(years);
  }

  /// Получить название дня недели на нужном языке
  static String _getWeekdayName(int weekday, dynamic l10n) {
    switch (weekday) {
      case 1: // Monday
        return l10n.weekdayMonday;
      case 2: // Tuesday
        return l10n.weekdayTuesday;
      case 3: // Wednesday
        return l10n.weekdayWednesday;
      case 4: // Thursday
        return l10n.weekdayThursday;
      case 5: // Friday
        return l10n.weekdayFriday;
      case 6: // Saturday
        return l10n.weekdaySaturday;
      case 7: // Sunday
        return l10n.weekdaySunday;
      default:
        return '';
    }
  }
}







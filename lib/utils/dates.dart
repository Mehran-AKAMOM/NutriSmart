/// Small date helpers (so we don't need the intl package).
class Dates {
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// yyyy-MM-dd key used for storing logs per day.
  static String key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime parse(String key) => DateTime.parse(key);

  static DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool isToday(DateTime d) => key(d) == key(DateTime.now());

  /// "Today", "Yesterday" or "Mon 3 Nov".
  static String friendly(DateTime d) {
    final today = dayOnly(DateTime.now());
    final diff = today.difference(dayOnly(d)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff == -1) return 'Tomorrow';
    return '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';
  }

  static String short(DateTime d) => '${d.day} ${_months[d.month - 1]}';

  static String weekday(DateTime d) => _weekdays[d.weekday - 1];
}

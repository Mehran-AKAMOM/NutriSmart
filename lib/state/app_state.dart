import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/food.dart';
import '../models/log_entry.dart';
import '../models/nutrients.dart';
import '../models/user_profile.dart';
import '../services/notification_service.dart';
import '../services/nutrition_calculator.dart';
import '../utils/dates.dart';

/// Reminder settings chosen by the user.
class ReminderSettings {
  final bool enabled;
  final TimeOfDay breakfast;
  final TimeOfDay lunch;
  final TimeOfDay dinner;
  final bool water;

  const ReminderSettings({
    this.enabled = false,
    this.breakfast = const TimeOfDay(hour: 7, minute: 30),
    this.lunch = const TimeOfDay(hour: 13, minute: 0),
    this.dinner = const TimeOfDay(hour: 19, minute: 30),
    this.water = true,
  });

  ReminderSettings copyWith({
    bool? enabled,
    TimeOfDay? breakfast,
    TimeOfDay? lunch,
    TimeOfDay? dinner,
    bool? water,
  }) =>
      ReminderSettings(
        enabled: enabled ?? this.enabled,
        breakfast: breakfast ?? this.breakfast,
        lunch: lunch ?? this.lunch,
        dinner: dinner ?? this.dinner,
        water: water ?? this.water,
      );

  static String _t(TimeOfDay t) => '${t.hour}:${t.minute}';
  static TimeOfDay _p(String? s, TimeOfDay fallback) {
    final parts = (s ?? '').split(':');
    if (parts.length != 2) return fallback;
    return TimeOfDay(
        hour: int.tryParse(parts[0]) ?? fallback.hour,
        minute: int.tryParse(parts[1]) ?? fallback.minute);
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'breakfast': _t(breakfast),
        'lunch': _t(lunch),
        'dinner': _t(dinner),
        'water': water,
      };

  factory ReminderSettings.fromJson(Map<String, dynamic> j) {
    const d = ReminderSettings();
    return ReminderSettings(
      enabled: j['enabled'] as bool? ?? false,
      breakfast: _p(j['breakfast'] as String?, d.breakfast),
      lunch: _p(j['lunch'] as String?, d.lunch),
      dinner: _p(j['dinner'] as String?, d.dinner),
      water: j['water'] as bool? ?? true,
    );
  }

  List<Reminder> toReminders() => [
        Reminder(1, 'Breakfast time 🍳', 'Log your breakfast in NutriSmart.',
            breakfast),
        Reminder(2, 'Lunch time 🥗', 'What are you having for lunch? Log it.',
            lunch),
        Reminder(3, 'Dinner time 🍲', 'Log dinner and check today\'s balance.',
            dinner),
        if (water) ...[
          const Reminder(4, 'Hydration check 💧', 'Time for a glass of water.',
              TimeOfDay(hour: 10, minute: 30)),
          const Reminder(5, 'Hydration check 💧', 'Have you had enough water today?',
              TimeOfDay(hour: 16, minute: 0)),
        ],
      ];
}

/// All app data, plus saving/loading it on the phone (SharedPreferences).
/// Screens read from this and call its methods; it notifies them to redraw.
class AppState extends ChangeNotifier {
  late SharedPreferences _prefs;

  UserProfile? profile;
  List<LogEntry> _logs = [];
  Map<String, double> _water = {}; // date -> ml
  List<WeightEntry> weights = [];
  List<FoodItem> favorites = [];
  List<FoodItem> recents = [];
  ReminderSettings reminders = const ReminderSettings();

  /// The day currently shown on the Today screen.
  DateTime selectedDay = Dates.dayOnly(DateTime.now());

  bool get hasProfile => profile != null;
  DailyTargets get targets => NutritionCalculator.targetsFor(profile!);

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs.getString('profile');
    if (p != null) profile = UserProfile.fromJson(jsonDecode(p));

    _logs = _decodeList('logs', LogEntry.fromJson);
    favorites = _decodeList('favorites', FoodItem.fromJson);
    recents = _decodeList('recents', FoodItem.fromJson);
    weights = _decodeList('weights', WeightEntry.fromJson);

    final w = _prefs.getString('water');
    if (w != null) {
      _water = (jsonDecode(w) as Map)
          .map((k, v) => MapEntry(k as String, (v as num).toDouble()));
    }
    final r = _prefs.getString('reminders');
    if (r != null) reminders = ReminderSettings.fromJson(jsonDecode(r));
  }

  List<T> _decodeList<T>(String key, T Function(Map<String, dynamic>) f) {
    final s = _prefs.getString(key);
    if (s == null) return [];
    try {
      return (jsonDecode(s) as List)
          .map((e) => f(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return []; // corrupted data: start fresh rather than crash
    }
  }

  Future<void> _save(String key, Object value) =>
      _prefs.setString(key, jsonEncode(value));

  // ---------------- Profile ----------------
  Future<void> saveProfile(UserProfile p) async {
    final first = profile == null;
    profile = p;
    await _save('profile', p.toJson());
    // Record weight on the progress chart when it is new or changed.
    if (first || weights.isEmpty || weights.last.kg != p.weightKg) {
      await logWeight(p.weightKg, notify: false);
    }
    notifyListeners();
  }

  // ---------------- Day selection ----------------
  void selectDay(DateTime d) {
    selectedDay = Dates.dayOnly(d);
    notifyListeners();
  }

  // ---------------- Food log ----------------
  List<LogEntry> entriesFor(DateTime day) {
    final k = Dates.key(day);
    return _logs.where((e) => e.date == k).toList()
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
  }

  Nutrients totalsFor(DateTime day) => entriesFor(day)
      .fold(Nutrients.zero, (sum, e) => sum + e.nutrients);

  Future<void> addEntry(FoodItem food, double grams, MealType meal,
      {DateTime? day}) async {
    final d = day ?? selectedDay;
    _logs.add(LogEntry(
      id: '${DateTime.now().microsecondsSinceEpoch}${Random().nextInt(999)}',
      date: Dates.key(d),
      meal: meal,
      food: food,
      grams: grams,
      loggedAt: DateTime.now(),
    ));
    // Keep the 20 most recent distinct foods for quick re-logging.
    recents.removeWhere((f) => f.id == food.id);
    recents.insert(0, food);
    if (recents.length > 20) recents = recents.sublist(0, 20);
    await _save('logs', _logs);
    await _save('recents', recents);
    notifyListeners();
  }

  Future<void> removeEntry(String id) async {
    _logs.removeWhere((e) => e.id == id);
    await _save('logs', _logs);
    notifyListeners();
  }

  Future<void> restoreEntry(LogEntry e) async {
    _logs.add(e);
    await _save('logs', _logs);
    notifyListeners();
  }

  // ---------------- Favourites ----------------
  bool isFavorite(FoodItem f) => favorites.any((x) => x.id == f.id);

  Future<void> toggleFavorite(FoodItem f) async {
    if (isFavorite(f)) {
      favorites.removeWhere((x) => x.id == f.id);
    } else {
      favorites.insert(0, f);
    }
    await _save('favorites', favorites);
    notifyListeners();
  }

  // ---------------- Water ----------------
  double waterFor(DateTime day) => _water[Dates.key(day)] ?? 0;

  Future<void> addWater(double ml, {DateTime? day}) async {
    final k = Dates.key(day ?? selectedDay);
    _water[k] = max(0, (_water[k] ?? 0) + ml);
    await _save('water', _water);
    notifyListeners();
  }

  // ---------------- Weight ----------------
  Future<void> logWeight(double kg, {bool notify = true}) async {
    final k = Dates.key(DateTime.now());
    weights.removeWhere((w) => w.date == k); // one entry per day
    weights.add(WeightEntry(k, kg));
    weights.sort((a, b) => a.date.compareTo(b.date));
    await _save('weights', weights);
    if (profile != null && profile!.weightKg != kg) {
      profile = profile!.copyWith(weightKg: kg);
      await _save('profile', profile!.toJson());
    }
    if (notify) notifyListeners();
  }

  // ---------------- Stats ----------------
  /// Number of consecutive days (ending today or yesterday) with something logged.
  int get streak {
    final days = _logs.map((e) => e.date).toSet();
    var d = Dates.dayOnly(DateTime.now());
    if (!days.contains(Dates.key(d))) d = d.subtract(const Duration(days: 1));
    var count = 0;
    while (days.contains(Dates.key(d))) {
      count++;
      d = d.subtract(const Duration(days: 1));
    }
    return count;
  }

  int get totalDaysLogged => _logs.map((e) => e.date).toSet().length;

  // ---------------- Reminders ----------------
  Future<void> saveReminders(ReminderSettings r) async {
    reminders = r;
    await _save('reminders', r.toJson());
    if (r.enabled) {
      await NotificationService.instance.scheduleDaily(r.toReminders());
    } else {
      await NotificationService.instance.cancelAll();
    }
    notifyListeners();
  }

  // ---------------- Demo data ----------------
  /// Fills the last 7 days with a realistic food log, water and weights so the
  /// charts can be demonstrated (e.g. for screenshots). Uses the built-in
  /// food table only.
  Future<void> loadDemoWeek(List<FoodItem> foods) async {
    FoodItem f(String id) => foods.firstWhere((x) => x.id == 'local_$id');
    final plans = <List<(MealType, String, num)>>[
      [
        (MealType.breakfast, 'oats', 60), (MealType.breakfast, 'banana', 120),
        (MealType.breakfast, 'milk', 250), (MealType.lunch, 'chicken', 150),
        (MealType.lunch, 'rice', 220), (MealType.lunch, 'sukuma', 150),
        (MealType.dinner, 'tilapia', 160), (MealType.dinner, 'sweet_potato', 200),
        (MealType.dinner, 'kachumbari', 80), (MealType.snack, 'greek_yoghurt', 170),
        (MealType.snack, 'peanuts', 30),
      ],
      [
        (MealType.breakfast, 'egg', 100), (MealType.breakfast, 'brown_bread', 60),
        (MealType.breakfast, 'chai', 250), (MealType.lunch, 'githeri', 400),
        (MealType.lunch, 'avocado', 100), (MealType.dinner, 'ugali', 250),
        (MealType.dinner, 'sukuma', 150), (MealType.dinner, 'nyama_choma', 160),
        (MealType.snack, 'mango', 200), (MealType.snack, 'whey', 30),
        (MealType.snack, 'milk', 250),
      ],
      [
        (MealType.breakfast, 'uji', 300), (MealType.breakfast, 'egg', 100),
        (MealType.lunch, 'beans', 250), (MealType.lunch, 'chapati', 140),
        (MealType.lunch, 'kachumbari', 80), (MealType.dinner, 'pilau', 350),
        (MealType.dinner, 'cabbage', 150), (MealType.snack, 'banana', 120),
        (MealType.snack, 'peanut_butter', 32), (MealType.snack, 'yoghurt', 150),
      ],
      [
        (MealType.breakfast, 'oats', 60), (MealType.breakfast, 'milk', 250),
        (MealType.breakfast, 'pawpaw', 150), (MealType.lunch, 'omena', 120),
        (MealType.lunch, 'ugali', 250), (MealType.lunch, 'sukuma', 150),
        (MealType.dinner, 'chicken', 180), (MealType.dinner, 'brown_rice', 220),
        (MealType.dinner, 'broccoli', 90), (MealType.snack, 'almonds', 28),
        (MealType.snack, 'orange', 130),
      ],
    ];

    final today = Dates.dayOnly(DateTime.now());
    for (var back = 6; back >= 0; back--) {
      final day = today.subtract(Duration(days: back));
      final key = Dates.key(day);
      // Keep real entries on past days; today is topped up.
      if (back > 0 && _logs.any((e) => e.date == key)) continue;
      var plan = plans[back % plans.length];
      if (back == 0) {
        // Today: only breakfast and lunch so far.
        plan = plan
            .where((p) => p.$1 == MealType.breakfast || p.$1 == MealType.lunch)
            .toList();
      }
      var i = 0;
      for (final (meal, id, grams) in plan) {
        final hour = switch (meal) {
          MealType.breakfast => 7,
          MealType.lunch => 13,
          MealType.dinner => 19,
          MealType.snack => 16,
        };
        _logs.add(LogEntry(
          id: 'demo_${key}_${i++}',
          date: key,
          meal: meal,
          food: f(id),
          grams: grams.toDouble(),
          loggedAt: DateTime(day.year, day.month, day.day, hour, i),
        ));
      }
      _water[key] = back == 0
          ? max(_water[key] ?? 0.0, 1250.0)
          : 1750.0 + (back % 3) * 250;
    }

    // A gentle weight trend toward the user's goal.
    final w = profile?.weightKg ?? 65;
    final step = switch (profile?.goal) {
      Goal.lose => -0.15,
      Goal.gain => 0.12,
      _ => 0.0,
    };
    weights = [
      for (var back = 6; back >= 0; back--)
        WeightEntry(Dates.key(today.subtract(Duration(days: back))),
            double.parse((w - step * back + (back == 0 ? 0 : (back.isEven ? 0.1 : -0.1)))
                .toStringAsFixed(1))),
    ];

    await _save('logs', _logs);
    await _save('water', _water);
    await _save('weights', weights);
    notifyListeners();
  }

  // ---------------- Reset ----------------
  Future<void> resetAll() async {
    await NotificationService.instance.cancelAll();
    await _prefs.clear();
    profile = null;
    _logs = [];
    _water = {};
    weights = [];
    favorites = [];
    recents = [];
    reminders = const ReminderSettings();
    selectedDay = Dates.dayOnly(DateTime.now());
    notifyListeners();
  }
}

/// Makes [AppState] available to every screen:  `AppScope.of(context)`.
/// Widgets that call it rebuild automatically when the state changes.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Read without subscribing to rebuilds (for use inside callbacks).
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

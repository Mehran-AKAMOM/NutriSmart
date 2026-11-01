import 'food.dart';
import 'nutrients.dart';

enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeInfo on MealType {
  String get label => switch (this) {
        MealType.breakfast => 'Breakfast',
        MealType.lunch => 'Lunch',
        MealType.dinner => 'Dinner',
        MealType.snack => 'Snacks',
      };

  /// A sensible default meal for the current time of day.
  static MealType forNow() {
    final h = DateTime.now().hour;
    if (h < 11) return MealType.breakfast;
    if (h < 16) return MealType.lunch;
    if (h < 21) return MealType.dinner;
    return MealType.snack;
  }
}

/// One food the user ate: which food, how much, which meal, which day.
class LogEntry {
  final String id;
  final String date; // yyyy-MM-dd
  final MealType meal;
  final FoodItem food;
  final double grams;
  final DateTime loggedAt;

  const LogEntry({
    required this.id,
    required this.date,
    required this.meal,
    required this.food,
    required this.grams,
    required this.loggedAt,
  });

  Nutrients get nutrients => food.forGrams(grams);

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'meal': meal.name,
        'food': food.toJson(),
        'grams': grams,
        'loggedAt': loggedAt.toIso8601String(),
      };

  factory LogEntry.fromJson(Map<String, dynamic> j) => LogEntry(
        id: j['id'] as String,
        date: j['date'] as String,
        meal: MealType.values.firstWhere((m) => m.name == j['meal'],
            orElse: () => MealType.snack),
        food: FoodItem.fromJson(Map<String, dynamic>.from(j['food'])),
        grams: (j['grams'] as num).toDouble(),
        loggedAt: DateTime.tryParse(j['loggedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// A body-weight measurement for the progress chart.
class WeightEntry {
  final String date;
  final double kg;
  const WeightEntry(this.date, this.kg);

  Map<String, dynamic> toJson() => {'date': date, 'kg': kg};
  factory WeightEntry.fromJson(Map<String, dynamic> j) =>
      WeightEntry(j['date'] as String, (j['kg'] as num).toDouble());
}

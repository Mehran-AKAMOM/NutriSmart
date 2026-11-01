import 'dart:math' as math;

import '../models/user_profile.dart';

/// Personal daily targets worked out from the user's profile.
class DailyTargets {
  final double kcal;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugarLimit;
  final double sodiumLimit; // mg
  final double iron; // mg
  final double vitaminC; // mg
  final double calcium; // mg
  final double waterMl;
  final double bmr;
  final double tdee;

  const DailyTargets({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugarLimit,
    required this.sodiumLimit,
    required this.iron,
    required this.vitaminC,
    required this.calcium,
    required this.waterMl,
    required this.bmr,
    required this.tdee,
  });
}

class NutritionCalculator {
  /// Basal metabolic rate, using the Mifflin-St Jeor equation (1990):
  ///   men:   10 × kg + 6.25 × cm − 5 × age + 5
  ///   women: 10 × kg + 6.25 × cm − 5 × age − 161
  static double bmr(UserProfile p) {
    final base = 10 * p.weightKg + 6.25 * p.heightCm - 5 * p.age;
    return p.sex == Sex.male ? base + 5 : base - 161;
  }

  static DailyTargets targetsFor(UserProfile p) {
    final b = bmr(p);
    final tdee = b * p.activity.factor; // total daily energy expenditure

    // Goal adjustment: a 500 kcal deficit loses about 0.5 kg a week; a small
    // 300 kcal surplus supports muscle gain with limited fat gain.
    // Under-18s get a gentler deficit because they are still growing.
    double kcal = switch (p.goal) {
      Goal.lose => tdee - (p.age < 18 ? 300 : 500),
      Goal.maintain => tdee,
      Goal.gain => tdee + 300,
    };
    final floor = p.sex == Sex.male ? 1500.0 : 1200.0;
    kcal = math.max(kcal, floor);

    // Protein in grams per kg of body weight.
    final proteinPerKg = switch (p.goal) {
      Goal.lose => 1.6, // protects muscle while in a deficit
      Goal.maintain => 1.2,
      Goal.gain => 1.8,
    };
    final protein = p.weightKg * proteinPerKg;
    final fat = kcal * 0.28 / 9; // 28% of energy from fat; 9 kcal per g
    final carbs = math.max(0.0, (kcal - protein * 4 - fat * 9) / 4);

    final teen = p.age >= 14 && p.age <= 18;
    final iron = p.sex == Sex.male
        ? (teen ? 11.0 : 8.0)
        : (teen ? 15.0 : (p.age > 50 ? 8.0 : 18.0));
    final vitC = p.sex == Sex.male ? (teen ? 75.0 : 90.0) : (teen ? 65.0 : 75.0);
    final calcium = p.age <= 18
        ? 1300.0
        : (p.age > 50 && p.sex == Sex.female) || p.age > 70
            ? 1200.0
            : 1000.0;

    return DailyTargets(
      kcal: kcal.roundToDouble(),
      protein: protein.roundToDouble(),
      carbs: carbs.roundToDouble(),
      fat: fat.roundToDouble(),
      fiber: (kcal / 1000 * 14).roundToDouble(), // 14 g per 1000 kcal
      sugarLimit: (kcal * 0.10 / 4).roundToDouble(), // WHO: <10% of energy
      sodiumLimit: 2300,
      iron: iron,
      vitaminC: vitC,
      calcium: calcium,
      waterMl: (p.weightKg * 35 / 50).round() * 50.0, // 35 ml/kg, nearest 50
      bmr: b.roundToDouble(),
      tdee: tdee.roundToDouble(),
    );
  }

  static String bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Healthy';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }
}

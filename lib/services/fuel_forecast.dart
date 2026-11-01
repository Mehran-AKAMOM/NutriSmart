import 'package:flutter/material.dart';

import '../data/local_foods.dart';
import '../models/food.dart';
import '../models/nutrients.dart';
import '../models/user_profile.dart';
import '../theme.dart';
import 'nutrition_calculator.dart';

/// One input to the forecast, scored 0..1.
class ForecastFactor {
  final String name;
  final IconData icon;
  final double score; // 0..1
  final double weight; // points it can contribute (out of 100)
  final String detail;
  final String fix; // what to do if it's low
  const ForecastFactor({
    required this.name,
    required this.icon,
    required this.score,
    required this.weight,
    required this.detail,
    required this.fix,
  });

  double get points => score * weight;
}

/// A food you could still eat tonight, and how much it would raise the score.
class TopUp {
  final String label;
  final FoodItem? food; // null for water
  final double amount; // grams, or ml for water
  final int gain;
  const TopUp(this.label, this.food, this.amount, this.gain);
}

class FuelForecast {
  final int score;
  final String zone;
  final String headline;
  final String session;
  final String effort; // RPE range
  final String duration;
  final Color color;
  final List<ForecastFactor> factors;
  final List<TopUp> topUps;
  final double penalty;

  const FuelForecast({
    required this.score,
    required this.zone,
    required this.headline,
    required this.session,
    required this.effort,
    required this.duration,
    required this.color,
    required this.factors,
    required this.topUps,
    required this.penalty,
  });

  /// The factor holding the score back the most.
  ForecastFactor get limiter => factors.reduce(
      (a, b) => (a.weight - a.points) >= (b.weight - b.points) ? a : b);
}

/// Fuel Forecast: predicts how hard you can train tomorrow from what you ate.
///
/// Based on sports-nutrition guidance:
///  * Carbohydrate stored as muscle glycogen is the main fuel for hard
///    exercise. Guidelines suggest about 3-5 g/kg/day for light training and
///    6-10 g/kg/day for intense training (ACSM / IOC consensus).
///  * Eating too little energy overall reduces performance and recovery.
///  * About 1.2-2.0 g/kg of protein a day supports muscle repair.
///  * Starting exercise even mildly dehydrated reduces performance.
///  * Iron (oxygen transport) and vitamin C (absorbs iron, repairs tissue)
///    support endurance and recovery.
///
/// It is an estimate from food only: it does not know about sleep, stress or
/// illness, so it is a guide, not a medical measurement.
class FuelForecaster {
  /// Linear 0..1 ramp between [lo] and [hi].
  static double _ramp(double x, double lo, double hi) =>
      ((x - lo) / (hi - lo)).clamp(0.0, 1.0);

  static FuelForecast compute({
    required Nutrients today,
    required Nutrients yesterday,
    required double waterMl,
    required DailyTargets t,
    required UserProfile p,
    bool withTopUps = true,
  }) {
    final kg = p.weightKg;

    // 1) Fuel tank: carbs per kg, weighted towards today.
    final carbGkg = yesterday.kcal > 0
        ? (0.65 * today.carbs + 0.35 * yesterday.carbs) / kg
        : today.carbs / kg;
    final carbScore = 0.1 + 0.9 * _ramp(carbGkg, 2.0, 5.0);

    // 2) Energy availability: calories vs target (very large surplus = a bit sluggish).
    final r = t.kcal <= 0 ? 0.0 : today.kcal / t.kcal;
    final energyScore = r <= 1.2
        ? 0.1 + 0.9 * _ramp(r, 0.5, 0.92)
        : 1.0 - 0.25 * _ramp(r, 1.2, 1.6);

    // 3) Repair: protein per kg.
    final protGkg = today.protein / kg;
    final proteinScore = 0.1 + 0.9 * _ramp(protGkg, 0.6, 1.6);

    // 4) Hydration.
    final hydrationScore = 0.1 + 0.9 * _ramp(waterMl / t.waterMl, 0.3, 1.0);

    // 5) Micronutrient support: iron + vitamin C.
    final micro = ((today.iron / t.iron).clamp(0.0, 1.0) +
            (today.vitaminC / t.vitaminC).clamp(0.0, 1.0)) /
        2;
    final microScore = _ramp(micro, 0.15, 0.9);

    // Penalties: lots of sugar or salt.
    var penalty = 0.0;
    if (today.sugar > t.sugarLimit) {
      penalty += ((today.sugar / t.sugarLimit - 1) * 10).clamp(0.0, 6.0);
    }
    if (today.sodium > t.sodiumLimit) {
      penalty += ((today.sodium / t.sodiumLimit - 1) * 8).clamp(0.0, 4.0);
    }

    final factors = [
      ForecastFactor(
        name: 'Fuel tank',
        icon: Icons.local_gas_station_rounded,
        score: carbScore,
        weight: 30,
        detail: '${carbGkg.toStringAsFixed(1)} g carbs per kg (aim 5+ for hard days)',
        fix: 'Add a carb-rich food tonight: ugali, rice, oats, sweet potato or a banana.',
      ),
      ForecastFactor(
        name: 'Energy',
        icon: Icons.local_fire_department_rounded,
        score: energyScore,
        weight: 25,
        detail: '${today.kcal.round()} of ${t.kcal.round()} kcal (${(r * 100).round()}%)',
        fix: r > 1.2
            ? 'You ate well over target. Keep tomorrow\'s session moderate.'
            : 'You\'re under-fuelled. Eat a proper meal before bed.',
      ),
      ForecastFactor(
        name: 'Repair',
        icon: Icons.fitness_center_rounded,
        score: proteinScore,
        weight: 20,
        detail: '${protGkg.toStringAsFixed(1)} g protein per kg (aim 1.6)',
        fix: 'Have a protein snack: Greek yoghurt, eggs, milk or beans.',
      ),
      ForecastFactor(
        name: 'Hydration',
        icon: Icons.water_drop_rounded,
        score: hydrationScore,
        weight: 15,
        detail: '${(waterMl / 1000).toStringAsFixed(2)} of ${(t.waterMl / 1000).toStringAsFixed(1)} L',
        fix: 'Drink 2 glasses of water now and one when you wake up.',
      ),
      ForecastFactor(
        name: 'Micronutrients',
        icon: Icons.spa_rounded,
        score: microScore,
        weight: 10,
        detail: 'Iron ${(today.iron / t.iron * 100).round()}% · Vitamin C ${(today.vitaminC / t.vitaminC * 100).round()}%',
        fix: 'Add greens or beans for iron and an orange or kachumbari for vitamin C.',
      ),
    ];

    final raw = factors.fold<double>(0, (s, f) => s + f.points) - penalty;
    final score = raw.clamp(0, 100).round();

    final (zone, headline, session, effort, duration, color) = _zoneFor(score, p);

    final topUps = withTopUps
        ? _topUps(score, today, yesterday, waterMl, t, p)
        : const <TopUp>[];

    return FuelForecast(
      score: score,
      zone: zone,
      headline: headline,
      session: session,
      effort: effort,
      duration: duration,
      color: color,
      factors: factors,
      topUps: topUps,
      penalty: penalty,
    );
  }

  static (String, String, String, String, String, Color) _zoneFor(
      int score, UserProfile p) {
    final hard = switch (p.goal) {
      Goal.gain => 'Heavy lifting or a sprint session',
      Goal.lose => 'Intervals or a long, hard run',
      Goal.maintain => 'Hard training: intervals, heavy lifts or a full match',
    };
    if (score >= 80) {
      return ('Go hard', 'Fully fuelled', hard, 'RPE 8–9', '60–90 min', AppColors.lime);
    }
    if (score >= 60) {
      return ('Train normally', 'Well fuelled',
          'Normal session: steady run, gym or football practice', 'RPE 6–7', '45–60 min',
          AppColors.violetSoft);
    }
    if (score >= 40) {
      return ('Keep it light', 'Partly fuelled',
          'Technique work, an easy jog or mobility', 'RPE 4–5', '30–40 min',
          AppColors.warning);
    }
    return ('Recover', 'Low on fuel',
        'Rest day: a walk, stretching and an early night', 'RPE 1–3', '20–30 min walk',
        AppColors.danger);
  }

  /// Tries foods you could still eat tonight and keeps the best score gains.
  static List<TopUp> _topUps(int base, Nutrients today, Nutrients yesterday,
      double waterMl, DailyTargets t, UserProfile p) {
    final ids = switch (p.diet) {
      DietType.vegan => ['ugali', 'oats', 'banana', 'sweet_potato', 'beans', 'githeri', 'peanut_butter', 'orange'],
      DietType.vegetarian => ['ugali', 'oats', 'banana', 'sweet_potato', 'greek_yoghurt', 'egg', 'githeri', 'milk', 'orange'],
      DietType.any => ['ugali', 'rice', 'oats', 'banana', 'sweet_potato', 'greek_yoghurt', 'egg', 'githeri', 'omena', 'orange'],
    };
    final results = <TopUp>[];
    for (final id in ids) {
      final match = localFoods.where((f) => f.id == 'local_$id');
      if (match.isEmpty) continue;
      final f = match.first;
      final grams = f.servingGrams;
      final next = compute(
        today: today + f.forGrams(grams),
        yesterday: yesterday,
        waterMl: waterMl,
        t: t,
        p: p,
        withTopUps: false,
      ).score;
      final gain = next - base;
      if (gain > 0) results.add(TopUp('${f.name} · ${f.servingLabel}', f, grams, gain));
    }
    // Water as an option too.
    if (waterMl < t.waterMl) {
      final next = compute(
        today: today,
        yesterday: yesterday,
        waterMl: waterMl + 500,
        t: t,
        p: p,
        withTopUps: false,
      ).score;
      if (next > base) results.add(TopUp('2 glasses of water · 500 ml', null, 500, next - base));
    }
    results.sort((a, b) => b.gain.compareTo(a.gain));
    return results.take(4).toList();
  }
}

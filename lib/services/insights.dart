import 'package:flutter/material.dart';

import '../models/nutrients.dart';
import '../models/user_profile.dart';
import 'nutrition_calculator.dart';

enum InsightKind { good, warning, tip }

class Insight {
  final InsightKind kind;
  final IconData icon;
  final String title;
  final String message;
  const Insight(this.kind, this.icon, this.title, this.message);
}

/// Rule-based "personal nutritionist": compares what you have eaten today
/// with your targets and suggests specific foods to close the gaps.
class InsightsEngine {
  static List<Insight> forDay({
    required Nutrients eaten,
    required DailyTargets t,
    required UserProfile profile,
    required double waterMl,
    required int entries,
    required bool isToday,
  }) {
    final hour = DateTime.now().hour;
    // Before the evening it is too early to say "you ate too little".
    final dayMostlyOver = !isToday || hour >= 18;
    final out = <Insight>[];

    if (entries == 0) {
      return [
        Insight(InsightKind.tip, Icons.restaurant, 'Start logging',
            isToday
                ? 'Add your first meal. Logging even roughly helps you spot patterns.'
                : 'Nothing was logged on this day.'),
      ];
    }

    double pct(double v, double target) => target <= 0 ? 0 : v / target;

    // --- Energy ---
    final kcalPct = pct(eaten.kcal, t.kcal);
    if (kcalPct > 1.1) {
      out.add(Insight(
        InsightKind.warning,
        Icons.local_fire_department,
        'Over your calorie target',
        'You are ${(eaten.kcal - t.kcal).round()} kcal over. '
            '${profile.goal == Goal.gain ? 'Fine for a bulk if it is mostly protein and carbs.' : 'Try a lighter dinner, like a salad, soup or grilled fish with vegetables.'}',
      ));
    } else if (dayMostlyOver && kcalPct < 0.7) {
      out.add(Insight(
        InsightKind.warning,
        Icons.battery_alert,
        'Too little energy',
        'Only ${(kcalPct * 100).round()}% of your calories. Eating too little '
            'slows growth and recovery. Add a snack like peanuts, a banana or yoghurt.',
      ));
    }

    // --- Protein ---
    if (pct(eaten.protein, t.protein) < (dayMostlyOver ? 0.8 : 0.4)) {
      final gap = (t.protein - eaten.protein).round();
      final ideas = switch (profile.diet) {
        DietType.vegan => 'beans, ndengu, lentils, tofu or peanuts',
        DietType.vegetarian => 'eggs, Greek yoghurt, milk, beans or ndengu',
        DietType.any => 'eggs, chicken, tilapia, omena or beans',
      };
      out.add(Insight(InsightKind.tip, Icons.fitness_center,
          'Protein: $gap g to go', 'Good options: $ideas.'));
    }

    // --- Fibre ---
    if (dayMostlyOver && pct(eaten.fiber, t.fiber) < 0.6) {
      out.add(const Insight(InsightKind.tip, Icons.grass, 'Low on fibre',
          'Add githeri, beans, oats, whole-wheat bread or an extra portion of '
              'greens. Fibre keeps you full for longer.'));
    }

    // --- Sugar ---
    if (eaten.sugar > t.sugarLimit) {
      out.add(Insight(
        InsightKind.warning,
        Icons.icecream,
        'Sugar is high (${eaten.sugar.round()} g)',
        'Your limit is about ${t.sugarLimit.round()} g. Sugar in fruit and milk '
            'is fine; cut soda, sweetened chai and mandazi first.',
      ));
    }

    // --- Sodium ---
    if (eaten.sodium > t.sodiumLimit) {
      out.add(Insight(
        InsightKind.warning,
        Icons.water_drop_outlined,
        'Salt is high (${eaten.sodium.round()} mg sodium)',
        'Aim for under 2300 mg. Smokies, samosas, chips and instant noodles '
            'add up fast.',
      ));
    }

    // --- Micronutrients (skin, hair, eyes, energy) ---
    if (dayMostlyOver && pct(eaten.iron, t.iron) < 0.5) {
      out.add(const Insight(InsightKind.tip, Icons.bloodtype, 'Iron is low',
          'Iron carries oxygen and supports energy and hair. Try beans, omena, '
              'spinach or lean beef, with an orange or kachumbari to absorb more.'));
    }
    if (dayMostlyOver && pct(eaten.vitaminC, t.vitaminC) < 0.5) {
      out.add(const Insight(InsightKind.tip, Icons.spa, 'Vitamin C for skin',
          'Vitamin C builds collagen for healthy skin. One orange, a slice of '
              'pawpaw or half a mango covers most of your day.'));
    }
    if (dayMostlyOver && pct(eaten.calcium, t.calcium) < 0.5) {
      out.add(const Insight(InsightKind.tip, Icons.accessibility_new,
          'Calcium for growing bones',
          'Have a glass of milk or mala, some yoghurt, or omena, which is one '
              'of the richest calcium sources.'));
    }

    // --- Water ---
    if (isToday && hour >= 15 && waterMl < t.waterMl * 0.5) {
      out.add(Insight(InsightKind.tip, Icons.local_drink, 'Drink some water',
          'Only ${waterMl.round()} ml so far out of ${t.waterMl.round()} ml.'));
    }

    if (out.isEmpty) {
      out.add(const Insight(InsightKind.good, Icons.verified, 'Great balance',
          'Your intake looks well balanced so far. Keep it up!'));
    }
    return out;
  }
}

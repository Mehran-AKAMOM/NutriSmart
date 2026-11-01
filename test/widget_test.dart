import 'package:flutter_test/flutter_test.dart';
import 'package:nutrismart/data/local_foods.dart';
import 'package:nutrismart/models/user_profile.dart';
import 'package:nutrismart/services/nutrition_calculator.dart';

void main() {
  const profile = UserProfile(
    name: 'Test',
    age: 17,
    sex: Sex.male,
    heightCm: 175,
    weightKg: 65,
    activity: ActivityLevel.moderate,
    goal: Goal.maintain,
    diet: DietType.any,
    budgetFriendly: false,
  );

  test('BMR follows Mifflin-St Jeor', () {
    // 10*65 + 6.25*175 - 5*17 + 5 = 1663.75
    expect(NutritionCalculator.bmr(profile), closeTo(1663.75, 0.01));
  });

  test('Targets are sensible', () {
    final t = NutritionCalculator.targetsFor(profile);
    expect(t.kcal, closeTo(1663.75 * 1.55, 1));
    expect(t.protein, 78); // 1.2 g/kg
    expect(t.calcium, 1300); // teenager
  });

  test('Food scaling works', () {
    final egg = localFoods.firstWhere((f) => f.id == 'local_egg');
    expect(egg.forGrams(100).kcal, 155);
    expect(egg.forGrams(50).kcal, closeTo(77.5, 0.01));
  });
}

import 'food.dart';
import 'nutrients.dart';
import 'user_profile.dart';

class Recipe {
  final String id;
  final String name;
  final String emoji;
  final String summary;
  final int minutes;
  final int servings;
  final List<String> ingredients;
  final List<String> steps;

  /// Nutrition for ONE serving.
  final Nutrients perServing;

  /// Approximate weight of one serving in grams (used when logging).
  final double servingGrams;

  final Set<Goal> goals;
  final DietType diet; // the most restrictive diet this recipe fits
  final bool budget;

  const Recipe({
    required this.id,
    required this.name,
    required this.emoji,
    required this.summary,
    required this.minutes,
    required this.servings,
    required this.ingredients,
    required this.steps,
    required this.perServing,
    required this.servingGrams,
    required this.goals,
    required this.diet,
    required this.budget,
  });

  /// Whether this recipe is OK for someone following [d].
  bool fitsDiet(DietType d) => switch (d) {
        DietType.any => true,
        DietType.vegetarian => diet != DietType.any,
        DietType.vegan => diet == DietType.vegan,
      };

  /// Converts the recipe into a loggable food (nutrients per 100 g).
  FoodItem toFood() => FoodItem(
        id: 'recipe_$id',
        name: name,
        source: FoodSource.recipe,
        per100g: perServing.scale(100 / servingGrams),
        servingGrams: servingGrams,
        servingLabel: '1 serving',
      );
}

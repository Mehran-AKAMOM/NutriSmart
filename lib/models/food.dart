import 'nutrients.dart';

/// Where a food's data came from.
enum FoodSource { local, usda, openFoodFacts, recipe }

extension FoodSourceLabel on FoodSource {
  String get label => switch (this) {
        FoodSource.local => 'NutriSmart database',
        FoodSource.usda => 'USDA FoodData Central',
        FoodSource.openFoodFacts => 'Open Food Facts',
        FoodSource.recipe => 'NutriSmart recipe',
      };
}

/// A food that can be logged. Nutrients are stored per 100 g.
class FoodItem {
  final String id;
  final String name;
  final String? brand;
  final FoodSource source;
  final Nutrients per100g;

  /// Size of one typical serving in grams, and how it is described.
  final double servingGrams;
  final String servingLabel;

  /// Extra search words (e.g. "kale" for sukuma wiki).
  final List<String> aliases;

  const FoodItem({
    required this.id,
    required this.name,
    this.brand,
    required this.source,
    required this.per100g,
    this.servingGrams = 100,
    this.servingLabel = '100 g',
    this.aliases = const [],
  });

  /// Nutrients in [grams] of this food.
  Nutrients forGrams(double grams) => per100g.scale(grams / 100);

  bool matches(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return true;
    if (name.toLowerCase().contains(q)) return true;
    if ((brand ?? '').toLowerCase().contains(q)) return true;
    return aliases.any((a) => a.toLowerCase().contains(q));
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brand': brand,
        'source': source.name,
        'per100g': per100g.toJson(),
        'servingGrams': servingGrams,
        'servingLabel': servingLabel,
      };

  factory FoodItem.fromJson(Map<String, dynamic> j) => FoodItem(
        id: j['id'] as String,
        name: j['name'] as String,
        brand: j['brand'] as String?,
        source: FoodSource.values.firstWhere(
          (s) => s.name == j['source'],
          orElse: () => FoodSource.local,
        ),
        per100g: Nutrients.fromJson(Map<String, dynamic>.from(j['per100g'])),
        servingGrams: (j['servingGrams'] as num?)?.toDouble() ?? 100,
        servingLabel: j['servingLabel'] as String? ?? '100 g',
      );
}

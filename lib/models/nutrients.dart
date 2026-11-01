/// A set of nutrient amounts.
///
/// Food items store their nutrients **per 100 g**. When a food is logged,
/// those values are scaled to the amount eaten with [scale].
class Nutrients {
  final double kcal;
  final double protein; // g
  final double carbs; // g
  final double fat; // g
  final double fiber; // g
  final double sugar; // g
  final double sodium; // mg
  final double iron; // mg
  final double vitaminC; // mg
  final double calcium; // mg

  const Nutrients({
    this.kcal = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber = 0,
    this.sugar = 0,
    this.sodium = 0,
    this.iron = 0,
    this.vitaminC = 0,
    this.calcium = 0,
  });

  static const zero = Nutrients();

  /// Multiplies every nutrient by [factor].
  /// e.g. a per-100 g value scaled by 1.5 gives the amount in 150 g.
  Nutrients scale(double factor) => Nutrients(
        kcal: kcal * factor,
        protein: protein * factor,
        carbs: carbs * factor,
        fat: fat * factor,
        fiber: fiber * factor,
        sugar: sugar * factor,
        sodium: sodium * factor,
        iron: iron * factor,
        vitaminC: vitaminC * factor,
        calcium: calcium * factor,
      );

  Nutrients operator +(Nutrients o) => Nutrients(
        kcal: kcal + o.kcal,
        protein: protein + o.protein,
        carbs: carbs + o.carbs,
        fat: fat + o.fat,
        fiber: fiber + o.fiber,
        sugar: sugar + o.sugar,
        sodium: sodium + o.sodium,
        iron: iron + o.iron,
        vitaminC: vitaminC + o.vitaminC,
        calcium: calcium + o.calcium,
      );

  Map<String, dynamic> toJson() => {
        'kcal': kcal,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'sugar': sugar,
        'sodium': sodium,
        'iron': iron,
        'vitaminC': vitaminC,
        'calcium': calcium,
      };

  factory Nutrients.fromJson(Map<String, dynamic> j) {
    double d(String k) => (j[k] as num?)?.toDouble() ?? 0;
    return Nutrients(
      kcal: d('kcal'),
      protein: d('protein'),
      carbs: d('carbs'),
      fat: d('fat'),
      fiber: d('fiber'),
      sugar: d('sugar'),
      sodium: d('sodium'),
      iron: d('iron'),
      vitaminC: d('vitaminC'),
      calcium: d('calcium'),
    );
  }

  /// Short constructor used by the built-in food table:
  /// n(kcal, protein, carbs, fat, fiber, sugar, sodium, iron, vitC, calcium)
  factory Nutrients.n(num kcal, num p, num c, num f, num fib, num sug, num na,
          num fe, num vc, num ca) =>
      Nutrients(
        kcal: kcal.toDouble(),
        protein: p.toDouble(),
        carbs: c.toDouble(),
        fat: f.toDouble(),
        fiber: fib.toDouble(),
        sugar: sug.toDouble(),
        sodium: na.toDouble(),
        iron: fe.toDouble(),
        vitaminC: vc.toDouble(),
        calcium: ca.toDouble(),
      );
}

enum Sex { male, female }

enum ActivityLevel { sedentary, light, moderate, active, veryActive }

enum Goal { lose, maintain, gain }

enum DietType { any, vegetarian, vegan }

extension ActivityInfo on ActivityLevel {
  String get label => switch (this) {
        ActivityLevel.sedentary => 'Sedentary',
        ActivityLevel.light => 'Light',
        ActivityLevel.moderate => 'Moderate',
        ActivityLevel.active => 'Active',
        ActivityLevel.veryActive => 'Very active',
      };

  String get description => switch (this) {
        ActivityLevel.sedentary => 'Mostly sitting, little exercise',
        ActivityLevel.light => 'Exercise 1–3 days a week',
        ActivityLevel.moderate => 'Exercise 3–5 days a week',
        ActivityLevel.active => 'Hard exercise 6–7 days a week',
        ActivityLevel.veryActive => 'Athlete / physical job + training',
      };

  /// Multiplier applied to BMR to estimate total daily energy use (TDEE).
  double get factor => switch (this) {
        ActivityLevel.sedentary => 1.2,
        ActivityLevel.light => 1.375,
        ActivityLevel.moderate => 1.55,
        ActivityLevel.active => 1.725,
        ActivityLevel.veryActive => 1.9,
      };
}

extension GoalInfo on Goal {
  String get label => switch (this) {
        Goal.lose => 'Lose weight',
        Goal.maintain => 'Maintain',
        Goal.gain => 'Build muscle',
      };
}

extension DietInfo on DietType {
  String get label => switch (this) {
        DietType.any => 'No restriction',
        DietType.vegetarian => 'Vegetarian',
        DietType.vegan => 'Vegan',
      };
}

class UserProfile {
  final String name;
  final int age;
  final Sex sex;
  final double heightCm;
  final double weightKg;
  final ActivityLevel activity;
  final Goal goal;
  final DietType diet;

  /// Prefer low-cost foods and recipes.
  final bool budgetFriendly;

  const UserProfile({
    required this.name,
    required this.age,
    required this.sex,
    required this.heightCm,
    required this.weightKg,
    required this.activity,
    required this.goal,
    required this.diet,
    required this.budgetFriendly,
  });

  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));

  UserProfile copyWith({double? weightKg}) => UserProfile(
        name: name,
        age: age,
        sex: sex,
        heightCm: heightCm,
        weightKg: weightKg ?? this.weightKg,
        activity: activity,
        goal: goal,
        diet: diet,
        budgetFriendly: budgetFriendly,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'sex': sex.name,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'activity': activity.name,
        'goal': goal.name,
        'diet': diet.name,
        'budgetFriendly': budgetFriendly,
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        name: j['name'] as String? ?? '',
        age: (j['age'] as num?)?.toInt() ?? 18,
        sex: Sex.values.firstWhere((e) => e.name == j['sex'],
            orElse: () => Sex.male),
        heightCm: (j['heightCm'] as num?)?.toDouble() ?? 170,
        weightKg: (j['weightKg'] as num?)?.toDouble() ?? 65,
        activity: ActivityLevel.values.firstWhere(
            (e) => e.name == j['activity'],
            orElse: () => ActivityLevel.moderate),
        goal: Goal.values.firstWhere((e) => e.name == j['goal'],
            orElse: () => Goal.maintain),
        diet: DietType.values.firstWhere((e) => e.name == j['diet'],
            orElse: () => DietType.any),
        budgetFriendly: j['budgetFriendly'] as bool? ?? false,
      );
}

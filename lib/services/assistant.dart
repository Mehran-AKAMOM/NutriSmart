import '../data/local_foods.dart';
import '../data/nutrient_guide.dart';
import '../data/recipes.dart';
import '../models/food.dart';
import '../models/recipe.dart';
import '../models/user_profile.dart';
import '../state/app_state.dart';
import '../utils/dates.dart';
import 'fuel_forecast.dart';
import 'nutrition_calculator.dart';

/// One reply from the assistant. Text may contain **bold** segments.
class AssistantReply {
  final String text;
  final List<String> suggestions;
  const AssistantReply(this.text, [this.suggestions = const []]);
}

/// NutriSmart's offline coach.
///
/// It doesn't use the internet or an AI model. It understands common
/// questions with keyword rules and answers from the user's real data (today's
/// log, targets, water, weight), the built-in food table, the recipes and the
/// nutrient guide. Everything is computed on the phone.
class NutriAssistant {
  final AppState state;
  NutriAssistant(this.state);

  static const defaultSuggestions = [
    'How hard should I train tomorrow?',
    'How am I doing today?',
    'What should I eat next?',
    'Calories in chapati',
    'Foods for healthy skin',
  ];

  AssistantReply greeting() {
    final name = state.profile?.name ?? '';
    return AssistantReply(
      'Hi $name 👋 I\'m your NutriSmart coach.\n\n'
      'Ask me about your day, what to eat next, the nutrition in a food, or '
      'how nutrients help your skin, hair, eyes and growth.',
      defaultSuggestions,
    );
  }

  AssistantReply reply(String input) {
    final q = _normalise(input);
    if (q.isEmpty) return greeting();
    final words = q.split(' ');

    bool has(List<String> keys) => keys.any((k) => _containsWord(q, k));

    // --- Small talk ---
    if (words.length <= 3 &&
        has(['hi', 'hello', 'hey', 'jambo', 'habari', 'sasa', 'yo'])) {
      return greeting();
    }
    if (has(['thanks', 'thank', 'asante', 'thx'])) {
      return const AssistantReply('Anytime! 💪 Keep logging and I\'ll keep the tips coming.',
          defaultSuggestions);
    }
    if (has(['help', 'what can you do', 'how do you work'])) {
      return const AssistantReply(
        'I can:\n'
        '• Summarise **your day** (calories, protein, water)\n'
        '• Suggest **what to eat next** based on what\'s left\n'
        '• Tell you the **nutrition of a food**, e.g. "protein in githeri"\n'
        '• Explain **nutrients**, e.g. "why do I need iron?"\n'
        '• Find foods for **skin, hair, eyes, growth or energy**\n'
        '• Check your **water, sugar, salt, BMI and streak**',
        defaultSuggestions,
      );
    }

    // "my sugar" / "my salt" are status questions, not about the food "Sugar".
    if (has(['my sugar', 'sugar today', 'sugar intake'])) return _sugar();
    if (has(['my salt', 'my sodium', 'salt today', 'sodium today'])) {
      return _sodium();
    }

    final food = _findFood(q);
    final nutrient = _findNutrient(q);
    final topic = _findTopic(q);

    // --- Nutrition of a specific food ---
    if (food != null &&
        (words.length <= 3 ||
            has(['calorie', 'calories', 'kcal', 'protein', 'carbs', 'carb', 'fat',
                'healthy', 'nutrition', 'nutrients', 'much', 'many', 'in', 'is',
                'good', 'bad', 'sugar', 'fibre', 'fiber', 'iron']))) {
      return _foodInfo(food);
    }

    // --- Fuel Forecast: how hard to train tomorrow ---
    if (has(['tomorrow', 'train', 'training', 'workout', 'effort', 'readiness',
        'forecast', 'how hard', 'exercise', 'gym', 'match', 'practice'])) {
      return _forecast();
    }

    // --- Protein status (no specific food) ---
    if (has(['protein']) &&
        !has(['why', 'what is', 'benefit', 'about']) &&
        has(['left', 'need', 'much', 'today', 'enough', 'more', 'get', 'eaten'])) {
      return _proteinStatus();
    }

    // --- Body topics: skin, hair, eyes, growth... ---
    if (topic != null) return _topicInfo(topic);

    // --- A nutrient from the guide ---
    if (nutrient != null) return _nutrientInfo(nutrient);

    // --- Today's summary ---
    if (has(['today', 'summary', 'doing', 'progress', 'so far', 'left', 'remaining',
        'calories', 'calorie', 'kcal', 'status', 'report'])) {
      return _todaySummary();
    }

    // --- Suggestions ---
    if (has(['eat', 'suggest', 'recommend', 'idea', 'ideas', 'hungry', 'dinner',
        'lunch', 'breakfast', 'snack', 'meal', 'cook'])) {
      return _suggest(q);
    }

    if (has(['water', 'hydrat', 'drink', 'thirsty'])) return _water();
    if (has(['sugar', 'sweet', 'soda', 'sugary'])) return _sugar();
    if (has(['salt', 'sodium', 'salty'])) return _sodium();
    if (has(['bmi', 'weight', 'lose', 'gain', 'bulk', 'cut', 'fat loss', 'muscle'])) {
      return _weight();
    }
    if (has(['streak', 'consistent', 'consistency', 'logged'])) return _streak();
    if (has(['recipe', 'recipes', 'cook'])) return _recipes();

    return const AssistantReply(
      'I\'m not sure about that one yet 🤔 I\'m an offline coach, so I work best '
      'with questions about your food log, foods and nutrients. Try one of these:',
      defaultSuggestions,
    );
  }

  // ---------------------------------------------------------------- answers

  AssistantReply _todaySummary() {
    final today = DateTime.now();
    final t = state.targets;
    final n = state.totalsFor(today);
    final water = state.waterFor(today);
    final entries = state.entriesFor(today).length;
    if (entries == 0) {
      return const AssistantReply(
        'You haven\'t logged anything today yet. Start with your last meal and '
        'I\'ll keep track of the rest.',
        ['What should I eat next?', 'Breakfast ideas', 'Calories in ugali'],
      );
    }
    final left = t.kcal - n.kcal;
    final pPct = (n.protein / t.protein * 100).round();
    final lines = <String>[
      '**Today so far** ($entries foods logged)',
      '• Calories: **${n.kcal.round()}** / ${t.kcal.round()} kcal '
          '(${left >= 0 ? '${left.round()} left' : '${(-left).round()} over'})',
      '• Protein: **${n.protein.round()} g** / ${t.protein.round()} g ($pPct%)',
      '• Carbs ${n.carbs.round()} g · Fat ${n.fat.round()} g · Fibre ${n.fiber.round()} g',
      '• Water: **${(water / 1000).toStringAsFixed(2)} L** / ${(t.waterMl / 1000).toStringAsFixed(1)} L',
    ];
    final tip = pPct < 60
        ? 'Biggest gap: **protein**. Make your next meal protein-rich.'
        : n.fiber < t.fiber * 0.5
            ? 'Biggest gap: **fibre**. Add beans, greens or fruit.'
            : water < t.waterMl * 0.5
                ? 'Don\'t forget to **drink water** 💧'
                : 'You\'re on track. Nice work! ✅';
    return AssistantReply('${lines.join('\n')}\n\n$tip',
        ['What should I eat next?', 'How much protein is left?', 'Check my sugar']);
  }

  AssistantReply _forecast() {
    final today = DateTime.now();
    if (state.entriesFor(today).isEmpty) {
      return const AssistantReply(
        'I predict tomorrow\'s training readiness from what you eat today. Log '
        'your meals first and ask me again.',
        ['What should I eat next?'],
      );
    }
    final f = FuelForecaster.compute(
      today: state.totalsFor(today),
      yesterday: state.totalsFor(today.subtract(const Duration(days: 1))),
      waterMl: state.waterFor(today),
      t: state.targets,
      p: state.profile!,
    );
    final lim = f.limiter;
    final boost = f.topUps.isEmpty
        ? ''
        : '\n\n**Boost it tonight:** ${f.topUps.take(2).map((u) => '${u.label} (+${u.gain})').join(', ')}.';
    return AssistantReply(
      '⚡ **Fuel Forecast for tomorrow: ${f.score}/100. ${f.zone}**\n\n'
      'Suggested session: ${f.session} (${f.effort}, ${f.duration}).\n\n'
      'Biggest limiter: **${lim.name}** (${lim.detail}). ${lim.fix}$boost',
      const ['What should I eat next?', 'How am I doing today?'],
    );
  }

  AssistantReply _proteinStatus() {
    final t = state.targets;
    final n = state.totalsFor(DateTime.now());
    final gap = (t.protein - n.protein).round();
    final picks = _proteinFoods().take(4).map((f) {
      final s = f.forGrams(f.servingGrams);
      return '• ${f.name}: **${s.protein.round()} g** per ${f.servingLabel}';
    }).join('\n');
    if (gap <= 0) {
      return AssistantReply(
          'You\'ve hit your protein goal today: **${n.protein.round()} g** of ${t.protein.round()} g. 💪',
          const ['How am I doing today?', 'Foods for muscle growth']);
    }
    return AssistantReply(
      'You\'ve had **${n.protein.round()} g** of protein. **$gap g** to go '
      '(target ${t.protein.round()} g).\n\nEasy ways to close the gap:\n$picks',
      const ['What should I eat next?', 'Why do I need protein?'],
    );
  }

  AssistantReply _foodInfo(FoodItem f) {
    final s = f.forGrams(f.servingGrams);
    final t = state.targets;
    final verdict = <String>[];
    if (s.protein >= 15) verdict.add('a great **protein** source');
    if (s.fiber >= 5) verdict.add('high in **fibre**');
    if (s.vitaminC >= 30) verdict.add('rich in **vitamin C**');
    if (s.calcium >= 200) verdict.add('high in **calcium**');
    if (s.iron >= 3) verdict.add('a good **iron** source');
    final warn = <String>[];
    if (s.sugar >= 20) warn.add('high in sugar');
    if (s.sodium >= 600) warn.add('salty');
    if (s.kcal >= t.kcal * 0.3) warn.add('very energy-dense');
    final buffer = StringBuffer()
      ..writeln('**${f.name}**, ${f.servingLabel}:')
      ..writeln('• ${s.kcal.round()} kcal (${(s.kcal / t.kcal * 100).round()}% of your day)')
      ..writeln('• Protein ${s.protein.toStringAsFixed(1)} g · Carbs ${s.carbs.toStringAsFixed(1)} g · Fat ${s.fat.toStringAsFixed(1)} g')
      ..write('• Fibre ${s.fiber.toStringAsFixed(1)} g · Sugar ${s.sugar.toStringAsFixed(1)} g');
    if (verdict.isNotEmpty) buffer.write('\n\n✅ It\'s ${_joinNatural(verdict)}.');
    if (warn.isNotEmpty) buffer.write('\n⚠️ Note: ${_joinNatural(warn)}, so watch the portion.');
    return AssistantReply(buffer.toString(),
        const ['What should I eat next?', 'How am I doing today?']);
  }

  AssistantReply _nutrientInfo(NutrientInfo n) {
    final today = state.totalsFor(DateTime.now());
    final t = state.targets;
    final tracked = switch (n.name) {
      'Protein' => 'Today: **${today.protein.round()} g** of ${t.protein.round()} g.',
      'Iron' => 'Today: **${today.iron.toStringAsFixed(1)} mg** of ${t.iron.round()} mg.',
      'Vitamin C' => 'Today: **${today.vitaminC.round()} mg** of ${t.vitaminC.round()} mg.',
      'Calcium' => 'Today: **${today.calcium.round()} mg** of ${t.calcium.round()} mg.',
      'Fibre' => 'Today: **${today.fiber.round()} g** of ${t.fiber.round()} g.',
      'Water' => 'Today: **${(state.waterFor(DateTime.now()) / 1000).toStringAsFixed(2)} L** of ${(t.waterMl / 1000).toStringAsFixed(1)} L.',
      _ => null,
    };
    return AssistantReply(
      '${n.emoji} **${n.name}** (${n.helps.join(', ')})\n\n'
      '${n.whatItDoes}\n\n'
      '**Low intake signs:** ${n.lowSigns}\n'
      '**Best sources:** ${n.sources.join(', ')}\n'
      '**How much:** ${n.dailyNeed}'
      '${tracked == null ? '' : '\n\n$tracked'}',
      const ['Foods for healthy skin', 'What should I eat next?'],
    );
  }

  AssistantReply _topicInfo(String topic) {
    final list = nutrientGuide.where((n) => n.helps.contains(topic)).toList();
    final foods = <String>{};
    for (final n in list) {
      foods.addAll(n.sources.take(2));
    }
    final emoji = switch (topic) {
      'Skin' => '✨',
      'Hair' => '💇',
      'Eyes' => '👁️',
      'Growth' => '📈',
      'Bones' => '🦴',
      _ => '⚡',
    };
    return AssistantReply(
      '$emoji For **${topic.toLowerCase()}**, focus on: '
      '${list.map((n) => '**${n.name}**').join(', ')}.\n\n'
      '${list.map((n) => '• ${n.name}: ${n.whatItDoes.split('.').first}.').join('\n')}\n\n'
      '**Foods to add:** ${foods.take(8).join(', ')}.',
      list.take(3).map((n) => 'Tell me about ${n.name.toLowerCase()}').toList(),
    );
  }

  AssistantReply _suggest(String q) {
    final p = state.profile!;
    final t = state.targets;
    final n = state.totalsFor(DateTime.now());
    final left = t.kcal - n.kcal;
    final proteinGap = t.protein - n.protein;

    String meal = 'next meal';
    if (q.contains('breakfast')) meal = 'breakfast';
    if (q.contains('lunch')) meal = 'lunch';
    if (q.contains('dinner') || q.contains('supper')) meal = 'dinner';
    if (q.contains('snack')) meal = 'snack';

    if (meal == 'snack' || (left > 0 && left < 350)) {
      final snacks = _snackFoods().take(4).map((f) {
        final s = f.forGrams(f.servingGrams);
        return '• ${f.name} (${f.servingLabel}): ${s.kcal.round()} kcal, ${s.protein.round()} g protein';
      }).join('\n');
      return AssistantReply(
          'You have **${left.round()} kcal** left. Good snack options:\n$snacks',
          const ['How much protein is left?', 'Recipes for me']);
    }
    if (left <= 0) {
      return const AssistantReply(
        'You\'ve reached your calorie target for today. If you\'re still hungry, '
        'go for something light and filling: kachumbari, a cup of cabbage, '
        'watermelon or plain yoghurt.',
        ['How am I doing today?', 'Check my sugar'],
      );
    }

    List<Recipe> options = recipes
        .where((r) => r.fitsDiet(p.diet))
        .where((r) => meal != 'breakfast' || _isBreakfast(r))
        .where((r) => meal == 'breakfast' || !_isBreakfast(r) || meal == 'next meal')
        .toList();
    if (p.budgetFriendly) {
      final cheap = options.where((r) => r.budget).toList();
      if (cheap.isNotEmpty) options = cheap;
    }
    // Rank: fits the remaining calories, then helps with protein if needed.
    options.sort((a, b) {
      double score(Recipe r) {
        final over = (r.perServing.kcal - left).clamp(0, 5000).toDouble();
        final proteinBonus = proteinGap > 20 ? r.perServing.protein * 6 : 0.0;
        return over * 2 - proteinBonus + (r.goals.contains(p.goal) ? -80 : 0);
      }

      return score(a).compareTo(score(b));
    });
    final picks = options.take(3).map((r) =>
        '• ${r.emoji} **${r.name}**: ${r.perServing.kcal.round()} kcal, ${r.perServing.protein.round()} g protein, ${r.minutes} min');
    final why = proteinGap > 20
        ? 'You still need **${proteinGap.round()} g protein**, so these are protein-forward.'
        : 'These fit the **${left.round()} kcal** you have left.';
    return AssistantReply(
      'For your $meal, try:\n${picks.join('\n')}\n\n$why '
      'Open the Recipes tab for the full steps.',
      const ['Snack ideas', 'How am I doing today?', 'Calories in githeri'],
    );
  }

  AssistantReply _water() {
    final t = state.targets;
    final w = state.waterFor(DateTime.now());
    final left = (t.waterMl - w).clamp(0, 10000);
    return AssistantReply(
      'Water today: **${(w / 1000).toStringAsFixed(2)} L** of ${(t.waterMl / 1000).toStringAsFixed(1)} L '
      '(${(w / t.waterMl * 100).round()}%).\n\n'
      '${left == 0 ? 'Target reached 🎉' : 'About **${(left / 250).ceil()} more glasses** to go. Even mild dehydration hurts focus and training.'}',
      const ['How am I doing today?', 'Tell me about water'],
    );
  }

  AssistantReply _sugar() {
    final t = state.targets;
    final n = state.totalsFor(DateTime.now());
    return AssistantReply(
      'Sugar today: **${n.sugar.round()} g** (limit about ${t.sugarLimit.round()} g).\n\n'
      '${n.sugar > t.sugarLimit ? '⚠️ You\'re over. The usual culprits are soda (53 g per 500 ml), sweetened chai and mandazi.' : '✅ Within your limit. Sugar from fruit and milk is fine; it\'s the added sugar to watch.'}',
      const ['Check my salt', 'Snack ideas'],
    );
  }

  AssistantReply _sodium() {
    final t = state.targets;
    final n = state.totalsFor(DateTime.now());
    return AssistantReply(
      'Sodium today: **${n.sodium.round()} mg** (limit ${t.sodiumLimit.round()} mg).\n\n'
      '${n.sodium > t.sodiumLimit ? '⚠️ Over the limit. Smokies, samosas, chips and instant noodles add up fast.' : '✅ Within your limit.'}',
      const ['Check my sugar', 'How am I doing today?'],
    );
  }

  AssistantReply _weight() {
    final p = state.profile!;
    final t = state.targets;
    final bmi = p.bmi;
    final w = state.weights;
    final trend = w.length >= 2
        ? '${(w.last.kg - w.first.kg) >= 0 ? '+' : ''}${(w.last.kg - w.first.kg).toStringAsFixed(1)} kg since ${Dates.short(Dates.parse(w.first.date))}'
        : 'Log your weight weekly on the Progress tab to see a trend.';
    final advice = switch (p.goal) {
      Goal.lose => 'Your target (${t.kcal.round()} kcal) is a gentle deficit. Keep protein high (${t.protein.round()} g) to protect muscle.',
      Goal.gain => 'Your target (${t.kcal.round()} kcal) is a small surplus. Hit ${t.protein.round()} g protein and train with progressive overload.',
      Goal.maintain => 'Eating about ${t.kcal.round()} kcal keeps you stable.',
    };
    return AssistantReply(
      'Weight **${p.weightKg.toStringAsFixed(1)} kg** · BMI **${bmi.toStringAsFixed(1)}** '
      '(${NutritionCalculator.bmiCategory(bmi)})\n$trend\n\n$advice'
      '${p.age < 18 ? '\n\nFor under-18s, BMI is only a rough guide.' : ''}',
      const ['How much protein is left?', 'What should I eat next?'],
    );
  }

  AssistantReply _streak() {
    final s = state.streak;
    return AssistantReply(
      s == 0
          ? 'No streak yet. Log something today to start one! 🔥'
          : '🔥 You\'re on a **$s-day** logging streak (${state.totalDaysLogged} days logged in total). Keep it going!',
      const ['How am I doing today?'],
    );
  }

  AssistantReply _recipes() {
    final p = state.profile!;
    final list = recipes.where((r) => r.fitsDiet(p.diet) && r.goals.contains(p.goal)).take(5);
    return AssistantReply(
      'Recipes that fit your **${p.goal.label.toLowerCase()}** goal:\n'
      '${list.map((r) => '• ${r.emoji} ${r.name} (${r.perServing.kcal.round()} kcal)').join('\n')}\n\n'
      'Open the Recipes tab to see the steps and log them in one tap.',
      const ['What should I eat next?', 'Breakfast ideas'],
    );
  }

  // ---------------------------------------------------------------- helpers

  static String _normalise(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-z0-9\s']"), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static bool _containsWord(String q, String key) =>
      key.contains(' ') ? q.contains(key) : RegExp('\\b$key').hasMatch(q);

  static String _joinNatural(List<String> parts) {
    if (parts.length == 1) return parts.first;
    return '${parts.sublist(0, parts.length - 1).join(', ')} and ${parts.last}';
  }

  /// Finds a food mentioned in the question (longest matching name wins).
  FoodItem? _findFood(String q) {
    FoodItem? best;
    var bestLen = 0;
    for (final f in [...localFoods, ...state.favorites, ...state.recents]) {
      final names = <String>{
        _normalise(f.name),
        _normalise(f.name.split(RegExp(r'[(,]')).first),
        ...f.aliases.map(_normalise),
      };
      for (final n in names) {
        if (n.length < 3) continue;
        if (RegExp('\\b${RegExp.escape(n)}\\b').hasMatch(q) && n.length > bestLen) {
          best = f;
          bestLen = n.length;
        }
      }
    }
    return best;
  }

  NutrientInfo? _findNutrient(String q) {
    const keys = {
      'vitamin c': 'Vitamin C', 'vit c': 'Vitamin C',
      'vitamin a': 'Vitamin A', 'vitamin d': 'Vitamin D',
      'omega': 'Omega-3 fats', 'iron': 'Iron', 'zinc': 'Zinc',
      'calcium': 'Calcium', 'fibre': 'Fibre', 'fiber': 'Fibre',
      'protein': 'Protein', 'water': 'Water',
    };
    for (final e in keys.entries) {
      if (_containsWord(q, e.key)) {
        // "water" alone is handled as a status question instead.
        if (e.key == 'water' && !q.contains('why') && !q.contains('about')) {
          return null;
        }
        return nutrientGuide.firstWhere((n) => n.name == e.value);
      }
    }
    return null;
  }

  String? _findTopic(String q) {
    const topics = {
      'skin': 'Skin', 'acne': 'Skin', 'hair': 'Hair', 'eye': 'Eyes',
      'eyes': 'Eyes', 'vision': 'Eyes', 'growth': 'Growth', 'grow': 'Growth',
      'taller': 'Growth', 'height': 'Growth', 'bone': 'Bones', 'bones': 'Bones',
      'energy': 'Energy', 'tired': 'Energy', 'focus': 'Energy',
    };
    for (final e in topics.entries) {
      if (_containsWord(q, e.key)) return e.value;
    }
    return null;
  }

  List<FoodItem> _byIds(List<String> ids) => ids
      .map((id) => localFoods.where((f) => f.id == 'local_$id'))
      .where((l) => l.isNotEmpty)
      .map((l) => l.first)
      .toList();

  List<FoodItem> _proteinFoods() => _byIds(switch (state.profile!.diet) {
        DietType.vegan => ['beans', 'ndengu', 'lentils', 'tofu', 'chickpeas', 'peanuts'],
        DietType.vegetarian => ['egg', 'greek_yoghurt', 'milk', 'beans', 'ndengu', 'lentils'],
        DietType.any => ['chicken', 'egg', 'tilapia', 'omena', 'greek_yoghurt', 'beans'],
      });

  List<FoodItem> _snackFoods() => _byIds(switch (state.profile!.diet) {
        DietType.vegan => ['banana', 'peanuts', 'mango', 'orange', 'almonds'],
        DietType.vegetarian => ['greek_yoghurt', 'banana', 'peanuts', 'egg', 'mango'],
        DietType.any => ['greek_yoghurt', 'egg', 'banana', 'peanuts', 'mango'],
      });

  static bool _isBreakfast(Recipe r) =>
      ['sukuma_eggs', 'overnight_oats', 'fruit_yoghurt', 'recovery_smoothie'].contains(r.id);
}

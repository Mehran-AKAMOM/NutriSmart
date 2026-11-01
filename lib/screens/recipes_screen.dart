import 'package:flutter/material.dart';

import '../data/recipes.dart';
import '../models/log_entry.dart';
import '../models/recipe.dart';
import '../models/user_profile.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';

/// Healthy recipe ideas, filtered to the user's goal, diet and budget.
class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  bool _matchGoal = true;
  bool _matchDiet = true;
  bool _budgetOnly = false;
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialised) {
      _budgetOnly = AppScope.read(context).profile?.budgetFriendly ?? false;
      _initialised = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = AppScope.of(context).profile!;
    final list = recipes.where((r) {
      if (_matchGoal && !r.goals.contains(profile.goal)) return false;
      if (_matchDiet && !r.fitsDiet(profile.diet)) return false;
      if (_budgetOnly && !r.budget) return false;
      return true;
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            const Text('Recipes', style: AppText.display),
            const SizedBox(height: 4),
            Text('${list.length} ideas picked for you', style: AppText.small),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _toggle(profile.goal.label, _matchGoal,
                  () => setState(() => _matchGoal = !_matchGoal)),
              if (profile.diet != DietType.any)
                _toggle(profile.diet.label, _matchDiet,
                    () => setState(() => _matchDiet = !_matchDiet)),
              _toggle('Budget', _budgetOnly,
                  () => setState(() => _budgetOnly = !_budgetOnly)),
            ]),
            const SizedBox(height: 16),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No recipes match these filters. Try turning one off.',
                    textAlign: TextAlign.center),
              ),
            ...list.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RecipeCard(recipe: e.value, index: e.key),
                )),
          ],
        ),
      ),
    );
  }
}

Widget _toggle(String label, bool selected, VoidCallback onTap) => Material(
      color: selected ? AppColors.ink : AppColors.surface,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (selected) ...[
              const Icon(Icons.check, size: 14, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : AppColors.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ]),
        ),
      ),
    );

const _tileColors = [AppColors.ink, AppColors.violet, AppColors.lime];

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final int index;
  const _RecipeCard({required this.recipe, required this.index});

  @override
  Widget build(BuildContext context) {
    final r = recipe;
    final color = _tileColors[index % _tileColors.length];
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => RecipeDetailScreen(recipe: r, color: color))),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(r.emoji, style: const TextStyle(fontSize: 38)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: -0.3)),
                  const SizedBox(height: 4),
                  Text(r.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.small),
                  const SizedBox(height: 8),
                  Row(children: [
                    _chip('${r.perServing.kcal.round()} kcal'),
                    const SizedBox(width: 6),
                    _chip('${r.perServing.protein.round()} g P'),
                    const SizedBox(width: 6),
                    _chip('${r.minutes} min'),
                  ]),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _chip(String s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(s,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
      );
}

class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;
  final Color color;
  const RecipeDetailScreen(
      {super.key, required this.recipe, this.color = AppColors.violet});

  @override
  Widget build(BuildContext context) {
    final r = recipe;
    final n = r.perServing;
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
        children: [
          Container(
            height: 190,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Text(r.emoji, style: const TextStyle(fontSize: 86)),
          ),
          const SizedBox(height: 18),
          Text(r.name, style: AppText.h1),
          const SizedBox(height: 6),
          Text(r.summary, style: AppText.body),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 6, children: [
            _tag(Icons.timer_outlined, '${r.minutes} min'),
            _tag(Icons.people_outline, 'Serves ${r.servings}'),
            _tag(Icons.eco_outlined,
                r.diet == DietType.any ? 'Meat / fish' : r.diet.label),
            if (r.budget) _tag(Icons.savings_outlined, 'Budget'),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: StatPill(
                    value: '${n.kcal.round()}',
                    label: 'kcal',
                    color: AppColors.ink,
                    filled: true)),
            const SizedBox(width: 8),
            Expanded(
                child: StatPill(
                    value: '${n.protein.round()}g',
                    label: 'Protein',
                    color: AppColors.violet)),
            const SizedBox(width: 8),
            Expanded(
                child: StatPill(
                    value: '${n.carbs.round()}g',
                    label: 'Carbs',
                    color: AppColors.carbs)),
            const SizedBox(width: 8),
            Expanded(
                child: StatPill(
                    value: '${n.fat.round()}g',
                    label: 'Fat',
                    color: AppColors.fat)),
          ]),
          const BigTitle('Ingredients'),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: r.ingredients
                  .map((i) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        child: Row(children: [
                          Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                  color: color, shape: BoxShape.circle)),
                          const SizedBox(width: 12),
                          Expanded(child: Text(i, style: AppText.body)),
                        ]),
                      ))
                  .toList(),
            ),
          ),
          const BigTitle('Method'),
          ...r.steps.asMap().entries.map((e) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                          color: AppColors.ink, shape: BoxShape.circle),
                      child: Text('${e.key + 1}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(e.value, style: AppText.body),
                    )),
                  ],
                ),
              )),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton.icon(
            icon: const Icon(Icons.add),
            label: Text('Log 1 serving · ${n.kcal.round()} kcal'),
            onPressed: () async {
              final meal = MealTypeInfo.forNow();
              await AppScope.read(context)
                  .addEntry(r.toFood(), r.servingGrams, meal);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Logged ${r.name} to ${meal.label}')));
            },
          ),
        ),
      ),
    );
  }

  Widget _tag(IconData icon, String s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: AppColors.muted),
          const SizedBox(width: 4),
          Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      );
}

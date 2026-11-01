import 'package:flutter/material.dart';

import '../models/food.dart';
import '../models/log_entry.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/ui.dart';

/// Choose how much you ate and which meal, see the nutrition, then log it.
class FoodDetailScreen extends StatefulWidget {
  final FoodItem food;
  final MealType? meal;
  const FoodDetailScreen({super.key, required this.food, this.meal});

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  late final TextEditingController _amount;
  bool _inServings = true;
  late MealType _meal;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(text: '1');
    _meal = widget.meal ?? MealTypeInfo.forNow();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  double get _grams {
    final v = double.tryParse(_amount.text.replaceAll(',', '.')) ?? 0;
    return _inServings ? v * widget.food.servingGrams : v;
  }

  void _switchUnit(bool servings) {
    // Keep the same quantity when switching between servings and grams.
    final grams = _grams;
    setState(() {
      _inServings = servings;
      final v = servings ? grams / widget.food.servingGrams : grams;
      _amount.text =
          v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);
    });
  }

  Future<void> _add() async {
    if (_grams <= 0) return;
    final state = AppScope.read(context);
    await state.addEntry(widget.food, _grams, _meal);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Added ${widget.food.name} to ${_meal.label}'),
      duration: const Duration(seconds: 2),
    ));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final food = widget.food;
    final n = food.forGrams(_grams);
    final t = state.targets;
    final fav = state.isFavorite(food);

    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SquareIconButton(
              icon: fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              foreground: fav ? AppColors.danger : AppColors.ink,
              onTap: () => state.toggleFavorite(food),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
        children: [
          Text(food.name, style: AppText.h1),
          const SizedBox(height: 4),
          Text(
              [
                if (food.brand != null && food.brand!.isNotEmpty) food.brand!,
                food.source.label,
              ].join(' · '),
              style: AppText.small),
          const SizedBox(height: 18),

          // ---- Hero: calories + macros ----
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(children: [
              HeroCircle(
                value: '${n.kcal.round()}',
                label: 'kcal',
                icon: Icons.restaurant_rounded,
                progress: n.kcal / t.kcal,
                size: 124,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(children: [
                  _macro('Protein', n.protein, AppColors.protein),
                  const SizedBox(height: 10),
                  _macro('Carbs', n.carbs, AppColors.carbs),
                  const SizedBox(height: 10),
                  _macro('Fat', n.fat, AppColors.fat),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 18),

          // ---- Amount ----
          Row(children: [
            SizedBox(
              width: 96,
              child: TextField(
                controller: _amount,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PillSelector<bool>(
                values: const [true, false],
                selected: _inServings,
                label: (v) => v ? 'Servings' : 'Grams',
                onChanged: _switchUnit,
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Text('1 serving = ${food.servingLabel} · total ${_grams.round()} g',
              style: AppText.small),
          const SizedBox(height: 16),

          // ---- Meal ----
          PillSelector<MealType>(
            values: MealType.values,
            selected: _meal,
            label: (m) => m == MealType.snack ? 'Snack' : m.label,
            onChanged: (m) => setState(() => _meal = m),
          ),

          const BigTitle('Nutrition'),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(children: [
              _row('Calories', '${n.kcal.round()}', 'kcal', n.kcal / t.kcal),
              _row('Protein', fmt(n.protein, decimals: 1), 'g', n.protein / t.protein),
              _row('Carbohydrates', fmt(n.carbs, decimals: 1), 'g', n.carbs / t.carbs),
              _row('Sugar', fmt(n.sugar, decimals: 1), 'g', n.sugar / t.sugarLimit),
              _row('Fat', fmt(n.fat, decimals: 1), 'g', n.fat / t.fat),
              _row('Fibre', fmt(n.fiber, decimals: 1), 'g', n.fiber / t.fiber),
              _row('Sodium', '${n.sodium.round()}', 'mg', n.sodium / t.sodiumLimit),
              _row('Iron', fmt(n.iron, decimals: 1), 'mg', n.iron / t.iron),
              _row('Vitamin C', fmt(n.vitaminC, decimals: 1), 'mg',
                  n.vitaminC / t.vitaminC),
              _row('Calcium', '${n.calcium.round()}', 'mg', n.calcium / t.calcium,
                  last: true),
            ]),
          ),
          const SizedBox(height: 8),
          const Text('% of your personal daily target', style: AppText.small),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: _grams > 0 ? _add : null,
            child: Text('Add to ${_meal.label} · ${n.kcal.round()} kcal'),
          ),
        ),
      ),
    );
  }

  Widget _macro(String label, double v, Color c) => Row(children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: AppText.body)),
        Text(fmt(v, decimals: 1),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const Text(' g', style: AppText.small),
      ]);

  Widget _row(String k, String v, String unit, double pct, {bool last = false}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Row(children: [
          Expanded(child: Text(k, style: const TextStyle(fontSize: 15))),
          Text(v,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          Text(' $unit', style: AppText.small),
          const SizedBox(width: 10),
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: 3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${(pct * 100).round()}%',
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
      );
}

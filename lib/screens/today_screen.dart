import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/log_entry.dart';
import '../services/insights.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils/dates.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/drumsticks.dart';
import '../widgets/ui.dart';
import 'add_food_screen.dart';
import 'chat_screen.dart';
import 'forecast_screen.dart';
import 'settings_screen.dart';

/// Daily dashboard: hero calories, nutrition tiles, coach advice, meals.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  void _openAdd(BuildContext context, [MealType? meal]) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => AddFoodScreen(meal: meal)));

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final profile = state.profile!;
    final day = state.selectedDay;
    final t = state.targets;
    final eaten = state.totalsFor(day);
    final entries = state.entriesFor(day);
    final water = state.waterFor(day);
    final isToday = Dates.isToday(day);
    final remaining = t.kcal - eaten.kcal;

    // Last 7 days ending on the selected day, for the week strip.
    final week = List.generate(7, (i) => day.subtract(Duration(days: 6 - i)));
    final weekKcal = week.map((d) => state.totalsFor(d).kcal).toList();

    final insights = InsightsEngine.forDay(
      eaten: eaten,
      t: t,
      profile: profile,
      waterMl: water,
      entries: entries.length,
      isToday: isToday,
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            GreetingHeader(
              name: profile.name,
              onAction: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
            const SizedBox(height: 20),

            // ---------------- Hero card ----------------
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  HeroCircle(
                    value: '${remaining.abs().round()}',
                    label: remaining >= 0 ? 'kcal left' : 'kcal over',
                    icon: Icons.local_fire_department_rounded,
                    progress: eaten.kcal / t.kcal,
                    size: 138,
                    color: remaining >= 0 ? AppColors.violet : AppColors.danger,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DayPicker(day: day),
                        const SizedBox(height: 6),
                        WeekStrip(
                          labels: week.map((d) => Dates.weekday(d).substring(0, 2)).toList(),
                          values: weekKcal,
                          target: t.kcal,
                          highlight: 6,
                        ),
                        const SizedBox(height: 12),
                        Row(children: [
                          _miniStat('Eaten', eaten.kcal.round().toString()),
                          const SizedBox(width: 14),
                          _miniStat('Goal', t.kcal.round().toString()),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ---------------- Fuel Forecast ----------------
            const SizedBox(height: 12),
            ForecastCard(day: day),

            // ---------------- Nutrition tiles ----------------
            BigTitle('Nutrition',
                trailing: PillButton(
                    label: 'Log food',
                    icon: Icons.add,
                    onTap: () => _openAdd(context))),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(children: [
                    MetricTile(
                      style: TileStyle.dark,
                      icon: Icons.restaurant_rounded,
                      title: 'Protein',
                      value: '${eaten.protein.round()}',
                      unit: 'of ${t.protein.round()} g',
                      // Each drumstick = 10% of the daily protein target.
                      visual: DrumstickMeter(progress: eaten.protein / t.protein),
                    ),
                    const SizedBox(height: 12),
                    MetricTile(
                      style: TileStyle.violet,
                      icon: Icons.bolt_rounded,
                      title: 'Energy in',
                      value: '${eaten.kcal.round()}',
                      unit: 'kcal',
                      height: 190,
                      visual: TickBars(
                        values: _energyBars(entries),
                        color: Colors.white,
                      ),
                    ),
                  ]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(children: [
                    MetricTile(
                      style: TileStyle.light,
                      icon: Icons.water_drop_rounded,
                      title: 'Water',
                      value: (water / 1000).toStringAsFixed(2),
                      unit: 'L',
                      onTap: () => state.addWater(250),
                      visual: WaveVisual(
                          level: water / t.waterMl, color: AppColors.water),
                      footer: _roundAdd(() => state.addWater(250)),
                    ),
                    const SizedBox(height: 12),
                    _AddFoodTile(onTap: () => _openAdd(context)),
                    const SizedBox(height: 12),
                    _FibreTile(value: eaten.fiber, target: t.fiber),
                  ]),
                ),
              ],
            ),

            // ---------------- Macros ----------------
            const BigTitle('Daily targets'),
            Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              child: Column(
                children: [
                  NutrientBar(
                      label: 'Protein',
                      value: eaten.protein,
                      target: t.protein,
                      unit: 'g',
                      color: AppColors.protein),
                  const SizedBox(height: 16),
                  NutrientBar(
                      label: 'Carbs',
                      value: eaten.carbs,
                      target: t.carbs,
                      unit: 'g',
                      color: AppColors.carbs),
                  const SizedBox(height: 16),
                  NutrientBar(
                      label: 'Fat',
                      value: eaten.fat,
                      target: t.fat,
                      unit: 'g',
                      color: AppColors.fat),
                  Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(bottom: 10),
                      title: const Text('Vitamins, minerals & limits',
                          style: AppText.label),
                      children: [
                        NutrientBar(
                            label: 'Iron',
                            value: eaten.iron,
                            target: t.iron,
                            unit: 'mg',
                            color: AppColors.danger),
                        const SizedBox(height: 14),
                        NutrientBar(
                            label: 'Vitamin C',
                            value: eaten.vitaminC,
                            target: t.vitaminC,
                            unit: 'mg',
                            color: AppColors.carbs),
                        const SizedBox(height: 14),
                        NutrientBar(
                            label: 'Calcium',
                            value: eaten.calcium,
                            target: t.calcium,
                            unit: 'mg',
                            color: AppColors.violet),
                        const SizedBox(height: 14),
                        NutrientBar(
                            label: 'Sugar (limit)',
                            value: eaten.sugar,
                            target: t.sugarLimit,
                            unit: 'g',
                            color: AppColors.ink,
                            isLimit: true),
                        const SizedBox(height: 14),
                        NutrientBar(
                            label: 'Sodium (limit)',
                            value: eaten.sodium,
                            target: t.sodiumLimit,
                            unit: 'mg',
                            color: AppColors.ink,
                            isLimit: true),
                      ],
                    ),
                  ),
                ],
              ),
              ),
            ),

            // ---------------- Coach ----------------
            BigTitle('Your coach',
                trailing: PillButton(
                    label: 'Ask coach',
                    icon: Icons.auto_awesome_rounded,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ChatScreen())))),
            ...insights.map((i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InsightCard(i),
                )),

            // ---------------- Meals ----------------
            const BigTitle('Meals'),
            ...MealType.values.map((m) => _MealCard(
                  meal: m,
                  entries: entries.where((e) => e.meal == m).toList(),
                  onAdd: () => _openAdd(context, m),
                )),
          ],
        ),
      ),
    );
  }

  /// Bars for the blue energy tile: one per logged food, padded so the tile
  /// always shows a full row of ticks.
  static List<double> _energyBars(List<LogEntry> entries) {
    final v = entries.map((e) => e.nutrients.kcal).toList();
    while (v.length < 14) {
      v.add(0);
    }
    return v.length > 22 ? v.sublist(v.length - 22) : v;
  }

  Widget _miniStat(String k, String v) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: AppText.small),
          Text(v,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.3)),
        ],
      );

  Widget _roundAdd(VoidCallback onTap) => Material(
        color: AppColors.ink,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.add, color: Colors.white, size: 16),
          ),
        ),
      );
}

class _DayPicker extends StatelessWidget {
  final DateTime day;
  const _DayPicker({required this.day});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    final isToday = Dates.isToday(day);
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: day,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
              );
              if (picked != null) state.selectDay(picked);
            },
            child: Text(Dates.friendly(day),
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: -0.3)),
          ),
        ),
        _chev(Icons.chevron_left,
            () => state.selectDay(day.subtract(const Duration(days: 1)))),
        const SizedBox(width: 4),
        _chev(Icons.chevron_right,
            isToday ? null : () => state.selectDay(day.add(const Duration(days: 1)))),
      ],
    );
  }

  Widget _chev(IconData icon, VoidCallback? onTap) => InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              size: 18, color: onTap == null ? AppColors.line : AppColors.ink),
        ),
      );
}

class _AddFoodTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddFoodTile({required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.lime,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: const SizedBox(
            height: 74,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: AppColors.ink, size: 18),
                SizedBox(width: 6),
                Text('Add Food',
                    style: TextStyle(
                        color: AppColors.ink, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      );
}

class _FibreTile extends StatelessWidget {
  final double value;
  final double target;
  const _FibreTile({required this.value, required this.target});

  @override
  Widget build(BuildContext context) {
    final pct = target <= 0 ? 0.0 : (value / target).clamp(0.0, 1.0);
    return Container(
      height: 104,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.grass_rounded, size: 16, color: AppColors.fiber),
            SizedBox(width: 6),
            Text('Fibre',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
          const Spacer(),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${value.round()}',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, height: 1)),
            Text(' / ${target.round()} g', style: AppText.small),
            const Spacer(),
            SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(
                value: math.max(pct, 0.02),
                strokeWidth: 4,
                color: AppColors.fiber,
                backgroundColor: AppColors.line,
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final MealType meal;
  final List<LogEntry> entries;
  final VoidCallback onAdd;
  const _MealCard(
      {required this.meal, required this.entries, required this.onAdd});

  IconData get _icon => switch (meal) {
        MealType.breakfast => Icons.free_breakfast_rounded,
        MealType.lunch => Icons.lunch_dining_rounded,
        MealType.dinner => Icons.dinner_dining_rounded,
        MealType.snack => Icons.cookie_rounded,
      };

  Color get _color => switch (meal) {
        MealType.breakfast => AppColors.carbs,
        MealType.lunch => AppColors.fiber,
        MealType.dinner => AppColors.violet,
        MealType.snack => AppColors.fat,
      };

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    final kcal = entries.fold<double>(0, (s, e) => s + e.nutrients.kcal);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(children: [
              IconBadge(icon: _icon, color: _color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meal.label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(
                        entries.isEmpty
                            ? 'Nothing logged yet'
                            : '${entries.length} item${entries.length == 1 ? '' : 's'}',
                        style: AppText.small),
                  ],
                ),
              ),
              Text('${kcal.round()}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 17)),
              const Text(' kcal', style: AppText.small),
              const SizedBox(width: 10),
              Material(
                color: AppColors.ink,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onAdd,
                  child: const Padding(
                    padding: EdgeInsets.all(7),
                    child: Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ]),
          ),
          ...entries.map((e) {
            final n = e.nutrients;
            return Dismissible(
              key: ValueKey(e.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: AppColors.danger,
                child: const Icon(Icons.delete_rounded, color: Colors.white),
              ),
              onDismissed: (_) {
                state.removeEntry(e.id);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Removed ${e.food.name}'),
                  action: SnackBarAction(
                      label: 'Undo',
                      textColor: Colors.white,
                      onPressed: () => state.restoreEntry(e)),
                ));
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(66, 10, 16, 12),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.line)),
                ),
                child: Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.food.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                            '${e.grams.round()} g · P ${n.protein.round()} · '
                            'C ${n.carbs.round()} · F ${n.fat.round()}',
                            style: AppText.small),
                      ],
                    ),
                  ),
                  Text('${n.kcal.round()}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const Text(' kcal', style: AppText.small),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }
}

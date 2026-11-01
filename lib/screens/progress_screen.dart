import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/nutrition_calculator.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils/dates.dart';
import '../widgets/charts.dart';
import '../widgets/ui.dart';

/// Trends: weekly calories chart, key stats, weight and BMI.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _days = 7;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final profile = state.profile!;
    final t = state.targets;
    final today = Dates.dayOnly(DateTime.now());

    final days =
        List.generate(_days, (i) => today.subtract(Duration(days: _days - 1 - i)));
    final totals = days.map(state.totalsFor).toList();
    final kcal = totals.map((n) => n.kcal).toList();
    final logged = kcal.where((k) => k > 0).toList();
    final minK = logged.isEmpty ? 0 : logged.reduce((a, b) => a < b ? a : b);
    final maxK = logged.isEmpty ? 0 : logged.reduce((a, b) => a > b ? a : b);
    final avgKcal =
        logged.isEmpty ? 0.0 : logged.reduce((a, b) => a + b) / logged.length;
    final proteinDays =
        totals.where((n) => n.protein >= t.protein * 0.9).length;
    final avgProtein = logged.isEmpty
        ? 0.0
        : totals.fold<double>(0, (s, n) => s + n.protein) / logged.length;

    final bmi = profile.bmi;
    final weights = state.weights.length > 12
        ? state.weights.sublist(state.weights.length - 12)
        : state.weights;

    final labels = days
        .map((d) => _days == 7 ? Dates.weekday(d).substring(0, 2) : '${d.day}')
        .toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Row(children: [
              const Expanded(child: Text('Calories', style: AppText.display)),
              SquareIconButton(
                  icon: Icons.monitor_weight_outlined,
                  onTap: () => _logWeight(context)),
            ]),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Range', style: AppText.small),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                logged.isEmpty
                                    ? '—'
                                    : minK == maxK
                                        ? '${minK.round()}'
                                        : '${minK.round()}-${maxK.round()}',
                                style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1.5,
                                    height: 1),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Text('kcal', style: AppText.small),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: PillSelector<int>(
                    values: const [7, 14],
                    selected: _days,
                    label: (d) => d == 7 ? 'Week' : '2 wk',
                    onChanged: (d) => setState(() => _days = d),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 18, 10, 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BigBarChart(values: kcal, labels: labels, target: t.kcal),
                  const SizedBox(height: 8),
                  Row(children: [
                    _legend(AppColors.violet, 'Calories eaten'),
                    const SizedBox(width: 14),
                    _legend(AppColors.limeDark, 'Target ${t.kcal.round()}'),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 18),
            StatRow(
                label: 'Average',
                value: avgKcal == 0 ? '—' : avgKcal.round().toString(),
                unit: 'kcal'),
            StatRow(label: 'Target', value: '${t.kcal.round()}', unit: 'kcal'),
            StatRow(
                label: 'Avg protein',
                value: avgProtein.round().toString(),
                unit: 'g / ${t.protein.round()}'),
            StatRow(
                label: 'Protein goal hit',
                value: '$proteinDays/$_days',
                unit: 'days'),
            StatRow(
                label: 'Logging streak',
                value: '${state.streak}',
                unit: state.streak == 1 ? 'day' : 'days',
                valueColor: AppColors.violet),

            const BigTitle('Body'),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Text('Weight', style: AppText.h2),
                    const Spacer(),
                    PillButton(
                        label: 'Log',
                        icon: Icons.add,
                        onTap: () => _logWeight(context)),
                  ]),
                  const SizedBox(height: 4),
                  Text('${profile.weightKg.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1)),
                  const SizedBox(height: 10),
                  if (weights.isNotEmpty)
                    SimpleLineChart(
                      values: weights.map((w) => w.kg).toList(),
                      labels: weights
                          .map((w) => Dates.short(Dates.parse(w.date)))
                          .toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            StatRow(
              label: 'BMI · ${NutritionCalculator.bmiCategory(bmi)}',
              value: bmi.toStringAsFixed(1),
            ),
            StatRow(label: 'Height', value: '${profile.heightCm.round()}', unit: 'cm'),
            StatRow(label: 'Resting burn (BMR)', value: '${t.bmr.round()}', unit: 'kcal'),

            const BigTitle('Connect'),
            StatRow(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFC4C02),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.directions_run_rounded,
                    color: Colors.white, size: 22),
              ),
              label: 'Strava',
              value: 'Coming soon',
              valueColor: AppColors.muted,
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Strava sync is coming in a future update!')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(Color c, String s) => Row(children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(s, style: AppText.small),
      ]);

  Future<void> _logWeight(BuildContext context) async {
    final state = AppScope.read(context);
    final ctrl =
        TextEditingController(text: state.profile!.weightKg.toStringAsFixed(1));
    final kg = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Today's weight", style: AppText.h2),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
          decoration: const InputDecoration(
              suffixText: 'kg', fillColor: AppColors.bg),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(90, 44)),
            onPressed: () => Navigator.pop(
                ctx, double.tryParse(ctrl.text.replaceAll(',', '.'))),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (kg != null && kg > 25 && kg < 300) await state.logWeight(kg);
  }
}

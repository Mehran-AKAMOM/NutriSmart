import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/user_profile.dart';
import '../services/nutrition_calculator.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// First-run setup. Also reused from Settings to edit the profile
/// (when [editing] is true).
class OnboardingScreen extends StatefulWidget {
  final bool editing;
  const OnboardingScreen({super.key, this.editing = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  Sex _sex = Sex.male;
  ActivityLevel _activity = ActivityLevel.moderate;
  Goal _goal = Goal.maintain;
  DietType _diet = DietType.any;
  bool _budget = false;
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    final p = AppScope.read(context).profile;
    if (p != null) {
      _name.text = p.name;
      _age.text = '${p.age}';
      _height.text = p.heightCm.toStringAsFixed(0);
      _weight.text = p.weightKg.toStringAsFixed(1);
      _sex = p.sex;
      _activity = p.activity;
      _goal = p.goal;
      _diet = p.diet;
      _budget = p.budgetFriendly;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  UserProfile? _buildProfile() {
    final age = int.tryParse(_age.text);
    final h = double.tryParse(_height.text.replaceAll(',', '.'));
    final w = double.tryParse(_weight.text.replaceAll(',', '.'));
    if (age == null || h == null || w == null) return null;
    return UserProfile(
      name: _name.text.trim(),
      age: age,
      sex: _sex,
      heightCm: h,
      weightKg: w,
      activity: _activity,
      goal: _goal,
      diet: _diet,
      budgetFriendly: _budget,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final p = _buildProfile();
    if (p == null) return;
    final state = AppScope.read(context);
    final t = NutritionCalculator.targetsFor(p);
    final goalNote = switch (p.goal) {
      Goal.lose => 'We subtracted a small deficit so you lose weight safely.',
      Goal.gain => 'We added a small surplus to support muscle gain.',
      Goal.maintain => 'Eating this much keeps your weight stable.',
    };

    // Show the user what we calculated and why, before saving.
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Your daily plan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _planRow('Calories', '${t.kcal.round()} kcal'),
            _planRow('Protein', '${t.protein.round()} g'),
            _planRow('Carbs', '${t.carbs.round()} g'),
            _planRow('Fat', '${t.fat.round()} g'),
            _planRow('Fibre', '${t.fiber.round()} g'),
            _planRow('Water', '${(t.waterMl / 1000).toStringAsFixed(1)} L'),
            const SizedBox(height: 12),
            Text(
              'Your body burns about ${t.bmr.round()} kcal at rest (BMR) and '
              '${t.tdee.round()} kcal with your activity level. $goalNote',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Edit')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Let's go")),
        ],
      ),
    );
    if (ok != true) return;
    await state.saveProfile(p);
    if (widget.editing && mounted) Navigator.pop(context);
  }

  Widget _planRow(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Text(k),
          const Spacer(),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
      );

  String? _numberValidator(String? v, double min, double max, String what) {
    final n = double.tryParse((v ?? '').replaceAll(',', '.'));
    if (n == null) return 'Enter your $what';
    if (n < min || n > max) return 'Enter a value between ${min.round()} and ${max.round()}';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.editing ? AppBar(title: const Text('Edit profile')) : null,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              if (!widget.editing) ...[
                const SizedBox(height: 8),
                Row(children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.violet,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.eco_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Text('NutriSmart', style: AppText.h1),
                ]),
                const SizedBox(height: 22),
                const Text("Let's build\nyour plan.", style: AppText.display),
                const SizedBox(height: 10),
                const Text(
                  'Tell us about yourself and we will work out your calorie '
                  'and nutrient targets.',
                  style: AppText.body,
                ),
                const SizedBox(height: 24),
              ],
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'First name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    controller: _age,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Age'),
                    validator: (v) => _numberValidator(v, 10, 100, 'age'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _height,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Height', suffixText: 'cm'),
                    validator: (v) => _numberValidator(v, 100, 250, 'height'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _weight,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Weight', suffixText: 'kg'),
                    validator: (v) => _numberValidator(v, 25, 300, 'weight'),
                  ),
                ),
              ]),
              _label('Sex'),
              PillSelector<Sex>(
                values: Sex.values,
                selected: _sex,
                label: (x) => x == Sex.male ? 'Male' : 'Female',
                onChanged: (x) => setState(() => _sex = x),
              ),
              _label('Goal'),
              PillSelector<Goal>(
                values: Goal.values,
                selected: _goal,
                label: (g) => g.label,
                onChanged: (g) => setState(() => _goal = g),
              ),
              _label('Activity level'),
              ...ActivityLevel.values.map((a) => _choiceTile(
                    selected: _activity == a,
                    title: a.label,
                    subtitle: a.description,
                    onTap: () => setState(() => _activity = a),
                  )),
              _label('Diet'),
              PillSelector<DietType>(
                values: DietType.values,
                selected: _diet,
                label: (d) => d == DietType.any ? 'Anything' : d.label,
                onChanged: (d) => setState(() => _diet = d),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                tileColor: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: const Text('Budget-friendly suggestions'),
                subtitle: const Text('Prioritise low-cost local foods and recipes'),
                value: _budget,
                onChanged: (v) => setState(() => _budget = v),
              ),
            ],
          ),
        ),
      ),
      // Pinned at the bottom so it is always reachable.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: _submit,
            child: Text(widget.editing ? 'Save changes' : 'Calculate my plan'),
          ),
        ),
      ),
    );
  }

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Text(s, style: AppText.h2),
      );

  Widget _choiceTile({
    required bool selected,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? AppColors.ink : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : AppColors.ink)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: selected ? Colors.white70 : AppColors.muted)),
                  ],
                ),
              ),
              Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: selected ? AppColors.lime : AppColors.line),
            ]),
          ),
        ),
      ),
    );
  }
}

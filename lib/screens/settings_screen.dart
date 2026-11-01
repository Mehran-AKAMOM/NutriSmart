import 'package:flutter/material.dart';

import '../data/local_foods.dart';
import '../models/user_profile.dart';
import '../services/food_api.dart';
import '../services/notification_service.dart';
import '../state/app_state.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = state.profile;
    if (p == null) return const SizedBox.shrink();
    final r = state.reminders;
    final t = state.targets;

    Future<void> pickTime(TimeOfDay current, ReminderSettings Function(TimeOfDay) apply) async {
      final picked = await showTimePicker(context: context, initialTime: current);
      if (picked != null) await state.saveReminders(apply(picked));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // ---- Profile ----
          _header(context, 'Profile'),
          ListTile(
            leading: CircleAvatar(
                child: Text(p.name.isEmpty ? '?' : p.name[0].toUpperCase())),
            title: Text(p.name),
            subtitle: Text('${p.age} y · ${p.heightCm.round()} cm · '
                '${p.weightKg.toStringAsFixed(1)} kg · ${p.goal.label}'),
            trailing: const Icon(Icons.edit),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const OnboardingScreen(editing: true))),
          ),
          ListTile(
            leading: const Icon(Icons.calculate_outlined),
            title: const Text('How your targets are calculated'),
            subtitle: Text('BMR ${t.bmr.round()} kcal × activity '
                '${p.activity.factor} = ${t.tdee.round()} kcal → target '
                '${t.kcal.round()} kcal'),
          ),

          ListTile(
            leading: const Icon(Icons.auto_graph_rounded),
            title: const Text('Load demo week'),
            subtitle: const Text('Fill the last 7 days with sample meals to preview the charts'),
            onTap: () async {
              await state.loadDemoWeek(localFoods);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Demo week loaded')));
            },
          ),
          // ---- Reminders ----
          _header(context, 'Reminders'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Daily meal reminders'),
            subtitle: const Text('Get a nudge to log each meal'),
            value: r.enabled,
            onChanged: (v) async {
              if (v) {
                final allowed = await NotificationService.instance.requestPermission();
                if (!allowed && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          'Notifications are blocked. Enable them in Android settings.')));
                }
              }
              await state.saveReminders(r.copyWith(enabled: v));
              if (v) await NotificationService.instance.showTest();
            },
          ),
          if (r.enabled) ...[
            _timeTile(context, 'Breakfast', r.breakfast,
                () => pickTime(r.breakfast, (x) => r.copyWith(breakfast: x))),
            _timeTile(context, 'Lunch', r.lunch,
                () => pickTime(r.lunch, (x) => r.copyWith(lunch: x))),
            _timeTile(context, 'Dinner', r.dinner,
                () => pickTime(r.dinner, (x) => r.copyWith(dinner: x))),
            SwitchListTile(
              secondary: const Icon(Icons.water_drop_outlined),
              title: const Text('Water reminders'),
              subtitle: const Text('10:30 and 16:00'),
              value: r.water,
              onChanged: (v) => state.saveReminders(r.copyWith(water: v)),
            ),
          ],

          // ---- Integrations ----
          _header(context, 'Integrations'),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFC4C02),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.directions_run, color: Colors.white, size: 20),
            ),
            title: const Text('Connect Strava'),
            subtitle: const Text('Coming soon: sync workouts to adjust calories'),
            trailing: const Chip(label: Text('Soon')),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Strava sync is coming in a future update!'))),
          ),

          // ---- About ----
          _header(context, 'About'),
          const ListTile(
            leading: Icon(Icons.storage_outlined),
            title: Text('Food data'),
            subtitle: Text('Built-in database (USDA & Kenya Food Composition '
                'Tables), USDA FoodData Central and Open Food Facts.'),
          ),
          if (FoodApi.usdaApiKey == 'DEMO_KEY')
            const ListTile(
              leading: Icon(Icons.key_outlined),
              title: Text('Online search uses the USDA demo key'),
              subtitle: Text('Limited to about 30 searches per hour. Add a free '
                  'personal key in food_api.dart.'),
            ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('NutriSmart v1.0'),
            subtitle: Text('Your data stays on this phone.'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Reset all data', style: TextStyle(color: Colors.red)),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Reset NutriSmart?'),
                  content: const Text(
                      'This deletes your profile, food log, weights and favourites.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Reset')),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
                await state.resetAll();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, String s) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(s,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700)),
      );

  Widget _timeTile(
          BuildContext context, String label, TimeOfDay time, VoidCallback onTap) =>
      ListTile(
        contentPadding: const EdgeInsets.only(left: 72, right: 16),
        title: Text(label),
        trailing: Text(time.format(context),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        onTap: onTap,
      );
}

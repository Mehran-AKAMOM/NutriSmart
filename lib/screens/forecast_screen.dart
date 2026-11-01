import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/log_entry.dart';
import '../services/fuel_forecast.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils/dates.dart';
import '../widgets/ui.dart';

/// Computes the forecast for the day after [day] from the app state.
FuelForecast forecastFor(AppState state, DateTime day) =>
    FuelForecaster.compute(
      today: state.totalsFor(day),
      yesterday: state.totalsFor(day.subtract(const Duration(days: 1))),
      waterMl: state.waterFor(day),
      t: state.targets,
      p: state.profile!,
    );

/// Half-circle gauge showing the 0-100 readiness score.
class ForecastGauge extends StatelessWidget {
  final int score;
  final Color color;
  final double width;
  final bool dark;
  const ForecastGauge({
    super.key,
    required this.score,
    required this.color,
    this.width = 150,
    this.dark = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * 0.62,
      child: CustomPaint(
        painter: _GaugePainter(score / 100, color, dark),
        child: Align(
          alignment: const Alignment(0, 0.75),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$score',
                  style: TextStyle(
                      color: dark ? Colors.white : AppColors.ink,
                      fontSize: width * 0.26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                      height: 1)),
              Text('/ 100',
                  style: TextStyle(
                      color: dark ? Colors.white54 : AppColors.muted,
                      fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color color;
  final bool dark;
  _GaugePainter(this.value, this.color, this.dark);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 13.0;
    final r = size.width / 2 - stroke / 2;
    final center = Offset(size.width / 2, size.height - 4);
    final rect = Rect.fromCircle(center: center, radius: r);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi, false,
        p..color = dark ? const Color(0xFF2C2935) : AppColors.line);
    canvas.drawArc(rect, math.pi, math.pi * value.clamp(0.02, 1.0), false,
        p..color = color);
    // Small ticks every 20 points.
    final tick = Paint()
      ..color = dark ? Colors.white24 : AppColors.muted
      ..strokeWidth = 2;
    for (var i = 0; i <= 5; i++) {
      final a = math.pi + math.pi * i / 5;
      final o1 = center + Offset(math.cos(a), math.sin(a)) * (r - stroke - 4);
      final o2 = center + Offset(math.cos(a), math.sin(a)) * (r - stroke - 10);
      canvas.drawLine(o1, o2, tick);
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value || old.color != color;
}

/// Compact dark card for the Today screen.
class ForecastCard extends StatelessWidget {
  final DateTime day;
  const ForecastCard({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final hasData = state.entriesFor(day).isNotEmpty;
    final f = forecastFor(state, day);
    final isToday = Dates.isToday(day);
    return Material(
      color: AppColors.ink,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => ForecastScreen(day: day))),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
          child: Row(children: [
            ForecastGauge(
                score: hasData ? f.score : 0,
                color: hasData ? f.color : AppColors.muted,
                width: 120),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.bolt_rounded, color: AppColors.lime, size: 16),
                    const SizedBox(width: 4),
                    Text(isToday ? 'FUEL FORECAST · TOMORROW' : 'FUEL FORECAST · NEXT DAY',
                        style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6)),
                  ]),
                  const SizedBox(height: 6),
                  Text(hasData ? f.zone : 'Log food first',
                      style: TextStyle(
                          color: hasData ? f.color : Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6)),
                  const SizedBox(height: 4),
                  Text(
                      hasData
                          ? '${f.effort} · ${f.duration}'
                          : 'Your plate predicts tomorrow\'s training.',
                      style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                  if (hasData && f.topUps.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Boost +${f.topUps.first.gain} tonight →',
                          style: const TextStyle(
                              color: AppColors.lime,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Full explanation of tomorrow's forecast.
class ForecastScreen extends StatelessWidget {
  final DateTime day;
  const ForecastScreen({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final f = forecastFor(state, day);
    final hasData = state.entriesFor(day).isNotEmpty;
    final isToday = Dates.isToday(day);
    final target = Dates.friendly(day.add(const Duration(days: 1)));

    return Scaffold(
      appBar: AppBar(title: const Text('Fuel Forecast')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          // ---- Hero ----
          Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(children: [
              Text('READINESS FOR ${target.toUpperCase()}',
                  style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
              const SizedBox(height: 14),
              ForecastGauge(
                  score: hasData ? f.score : 0,
                  color: hasData ? f.color : AppColors.muted,
                  width: 220),
              const SizedBox(height: 10),
              Text(hasData ? f.zone : 'Log some food first',
                  style: TextStyle(
                      color: hasData ? f.color : Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8)),
              const SizedBox(height: 4),
              Text(
                hasData
                    ? '${f.headline} based on what you ate ${isToday ? 'today' : 'on ${Dates.friendly(day)}'}'
                    : 'The forecast is built from your food log.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ]),
          ),
          const SizedBox(height: 12),

          if (hasData) ...[
            // ---- Recommended session ----
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.lime,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recommended session',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(f.session,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 19,
                          letterSpacing: -0.4,
                          height: 1.2)),
                  const SizedBox(height: 12),
                  Row(children: [
                    _chip(Icons.speed_rounded, f.effort),
                    const SizedBox(width: 8),
                    _chip(Icons.timer_outlined, f.duration),
                  ]),
                ],
              ),
            ),

            // ---- Factors ----
            const BigTitle("What's driving it"),
            ...f.factors.map((x) => _FactorRow(factor: x, isLimiter: x == f.limiter)),
            if (f.penalty >= 1)
              StatRow(
                label: 'Sugar / salt penalty',
                value: '−${f.penalty.round()}',
                unit: 'pts',
                valueColor: AppColors.danger,
              ),

            // ---- Boost tonight ----
            if (isToday && f.topUps.isNotEmpty) ...[
              BigTitle('Boost it tonight',
                  trailing: Text('predicted gain', style: AppText.small)),
              ...f.topUps.map((u) => _TopUpRow(topUp: u, day: day)),
            ],
          ],

          // ---- How it works ----
          const BigTitle('How it works'),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Text(
              'NutriSmart scores five things that affect how well your body can '
              'train the next day:\n\n'
              '• Fuel tank (30 pts): carbs are stored in your muscles as glycogen, '
              'the main fuel for hard exercise. Sports-nutrition guidelines suggest '
              'about 3–5 g per kg of body weight for light days and 6–10 g/kg for '
              'intense ones.\n'
              '• Energy (25 pts): eating far below your needs lowers performance '
              'and recovery.\n'
              '• Repair (20 pts): about 1.2–2.0 g/kg of protein helps muscles recover.\n'
              '• Hydration (15 pts): starting exercise dehydrated reduces performance.\n'
              '• Micronutrients (10 pts): iron carries oxygen; vitamin C helps you '
              'absorb iron and repair tissue.\n\n'
              'Very high sugar or salt costs a few points. It\'s an estimate from food '
              'only. It can\'t see your sleep, stress or illness, so listen to your body.',
              style: AppText.body,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: AppColors.lime, size: 15),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      );
}

class _FactorRow extends StatelessWidget {
  final ForecastFactor factor;
  final bool isLimiter;
  const _FactorRow({required this.factor, required this.isLimiter});

  @override
  Widget build(BuildContext context) {
    final f = factor;
    final color = f.score >= 0.75
        ? AppColors.limeDark
        : f.score >= 0.45
            ? AppColors.warning
            : AppColors.danger;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: isLimiter
            ? Border.all(color: AppColors.violet, width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            IconBadge(icon: f.icon, color: AppColors.violet, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(f.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    if (isLimiter) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.violet,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('Biggest limiter',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ]),
                  Text(f.detail, style: AppText.small),
                ],
              ),
            ),
            Text('${f.points.round()}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Text('/${f.weight.round()}', style: AppText.small),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: f.score,
              minHeight: 7,
              color: color,
              backgroundColor: AppColors.line,
            ),
          ),
          if (f.score < 0.75) ...[
            const SizedBox(height: 8),
            Text('💡 ${f.fix}', style: AppText.body),
          ],
        ],
      ),
    );
  }
}

class _TopUpRow extends StatelessWidget {
  final TopUp topUp;
  final DateTime day;
  const _TopUpRow({required this.topUp, required this.day});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.read(context);
    final u = topUp;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          child: Row(children: [
            IconBadge(
              icon: u.food == null ? Icons.water_drop_rounded : Icons.restaurant_rounded,
              color: u.food == null ? AppColors.water : AppColors.limeDark,
              size: 38,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(u.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Text('+${u.gain}',
                style: const TextStyle(
                    color: AppColors.limeDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 18)),
            const SizedBox(width: 8),
            Material(
              color: AppColors.ink,
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () async {
                  if (u.food == null) {
                    await state.addWater(u.amount, day: day);
                  } else {
                    await state.addEntry(u.food!, u.amount, MealType.snack, day: day);
                  }
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Logged. Forecast +${u.gain}')));
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Text('Log',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

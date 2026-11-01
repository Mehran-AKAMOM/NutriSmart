import 'package:flutter/material.dart';

import '../data/nutrient_guide.dart';
import '../theme.dart';

/// Nutrient guide: how nutrients affect skin, hair, eyes, growth and energy.
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  String? _filter;

  static const _topics = ['Skin', 'Hair', 'Eyes', 'Growth', 'Energy', 'Bones'];

  @override
  Widget build(BuildContext context) {
    final items = _filter == null
        ? nutrientGuide
        : nutrientGuide.where((n) => n.helps.contains(_filter)).toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            const Text('Learn', style: AppText.display),
            const SizedBox(height: 4),
            const Text('How food shapes your skin, hair, eyes and growth',
                style: AppText.small),
            const SizedBox(height: 16),

            // Featured card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.violet,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tip of the day',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                      SizedBox(height: 6),
                      Text('Pair iron with vitamin C',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5)),
                      SizedBox(height: 6),
                      Text(
                          'Beans + kachumbari, or sukuma + an orange, can help you absorb more iron.',
                          style: TextStyle(color: Colors.white, fontSize: 13, height: 1.3)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🍊', style: TextStyle(fontSize: 30)),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _chip('All', _filter == null, () => setState(() => _filter = null)),
                  ..._topics.map((t) =>
                      _chip(t, _filter == t, () => setState(() => _filter = t))),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ...items.map((n) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(22),
                    clipBehavior: Clip.antiAlias,
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        leading: Container(
                          width: 46,
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.bg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(n.emoji, style: const TextStyle(fontSize: 22)),
                        ),
                        title: Text(n.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16)),
                        subtitle: Text(n.helps.join(' · '), style: AppText.small),
                        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _section('What it does', n.whatItDoes),
                          _section('Signs you may be low', n.lowSigns),
                          _section('How much you need', n.dailyNeed),
                          const SizedBox(height: 10),
                          const Text('Good sources', style: AppText.label),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: n.sources
                                .map((s) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.bg,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(s,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600)),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
            const SizedBox(height: 8),
            const Text(
              'General information for healthy teens and adults, not medical '
              'advice. If you think you have a deficiency, speak to a doctor.',
              style: AppText.small,
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Material(
          color: selected ? AppColors.ink : AppColors.surface,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(label,
                  style: TextStyle(
                      color: selected ? Colors.white : AppColors.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ),
          ),
        ),
      );

  Widget _section(String title, String body) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppText.label),
            const SizedBox(height: 3),
            Text(body, style: AppText.body),
          ],
        ),
      );
}

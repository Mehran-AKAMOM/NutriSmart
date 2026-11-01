import 'package:flutter/material.dart';

import '../theme.dart';
import 'chat_screen.dart';
import 'learn_screen.dart';
import 'progress_screen.dart';
import 'recipes_screen.dart';
import 'today_screen.dart';

/// Bottom-navigation container for the four main tabs.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _pages = [
    TodayScreen(),
    ProgressScreen(),
    RecipesScreen(),
    ChatScreen(),
    LearnScreen(),
  ];

  static const _items = [
    (Icons.home_rounded, 'Today'),
    (Icons.bar_chart_rounded, 'Progress'),
    (Icons.restaurant_menu_rounded, 'Recipes'),
    (Icons.auto_awesome_rounded, 'Coach'),
    (Icons.school_rounded, 'Learn'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 10),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 6)),
            ],
          ),
          child: Row(
            children: List.generate(_items.length, (i) {
              final selected = i == _index;
              final (icon, label) = _items[i];
              return Expanded(
                flex: selected ? 5 : 3,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _index = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    height: 50,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.ink : Colors.transparent,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon,
                            size: 22,
                            color: selected ? AppColors.lime : AppColors.muted),
                        if (selected) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(label,
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../data/local_foods.dart';
import '../models/food.dart';
import '../models/log_entry.dart';
import '../services/food_api.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/ui.dart';
import 'food_detail_screen.dart';
import 'scanner_screen.dart';

/// Find a food to log: search (offline + USDA), favourites, recents, scan.
class AddFoodScreen extends StatefulWidget {
  final MealType? meal;
  const AddFoodScreen({super.key, this.meal});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _query = TextEditingController();
  Timer? _debounce;
  List<FoodItem> _online = [];
  bool _loadingOnline = false;
  String? _onlineError;
  String _lastOnlineQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    setState(() {}); // refresh the offline results instantly
    _debounce?.cancel();
    // Wait until the user stops typing before calling the online API.
    _debounce = Timer(const Duration(milliseconds: 700), _searchOnline);
  }

  int _requestId = 0;

  Future<void> _searchOnline() async {
    final q = _query.text.trim();
    if (q.length < 3 || q == _lastOnlineQuery) return;
    _lastOnlineQuery = q;
    // Only the most recent search is allowed to update the screen, so a
    // slow older request can't overwrite newer results.
    final id = ++_requestId;
    setState(() {
      _loadingOnline = true;
      _onlineError = null;
    });
    List<FoodItem>? results;
    Object? error;
    try {
      try {
        results = await FoodApi.searchUsda(q);
      } catch (_) {
        // The USDA API fails intermittently; one quick retry usually works.
        await Future.delayed(const Duration(milliseconds: 800));
        results = await FoodApi.searchUsda(q);
      }
      _onlineSource = 'USDA FoodData Central';
    } catch (e) {
      // USDA unavailable (rate limit, rejected query, outage): fall back to
      // Open Food Facts so the user still gets online results.
      try {
        results = await FoodApi.searchOpenFoodFacts(q);
        _onlineSource = 'Open Food Facts';
      } catch (e2) {
        error = e2;
        _onlineSource = 'Online search';
      }
    }
    if (!mounted || id != _requestId) return;
    final String? message = switch (error) {
      null => null,
      FoodApiException _ =>
        'Online food databases are busy right now. Showing offline foods; '
            'try again in a minute.',
      _ => 'No internet connection. Showing offline foods only.',
    };
    final found = results ?? <FoodItem>[];
    setState(() {
      _loadingOnline = false;
      _online = found;
      _onlineError = message;
    });
  }

  String _onlineSource = 'Online foods';

  Future<void> _open(FoodItem food) async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => FoodDetailScreen(food: food, meal: widget.meal)),
    );
    if (added == true && mounted) Navigator.pop(context);
  }

  Future<void> _scan() async {
    final food = await Navigator.push<FoodItem>(
        context, MaterialPageRoute(builder: (_) => const ScannerScreen()));
    if (food != null && mounted) _open(food);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final q = _query.text.trim();
    final local = localFoods.where((f) => f.matches(q)).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.meal == null
              ? 'Log food'
              : 'Add to ${widget.meal!.label}'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SquareIconButton(
                icon: Icons.qr_code_scanner_rounded,
                background: AppColors.ink,
                foreground: Colors.white,
                onTap: _scan,
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(124),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                  child: TextField(
                    controller: _query,
                    onChanged: _onChanged,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _searchOnline(),
                    decoration: InputDecoration(
                      hintText: 'Search e.g. "chapati", "banana", "chicken"',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: q.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _query.clear();
                                setState(() {
                                  _online = [];
                                  _lastOnlineQuery = '';
                                });
                              },
                            ),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.ink,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                    tabs: const [
                      Tab(text: 'Search', height: 38),
                      Tab(text: 'Favourites', height: 38),
                      Tab(text: 'Recent', height: 38),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            // ---- Search tab ----
            ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _header(context, 'NutriSmart foods', '${local.length}'),
                if (local.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('No offline matches.'),
                  ),
                ...local.take(q.isEmpty ? 60 : 30).map((f) => _FoodTile(food: f, onTap: () => _open(f))),
                if (q.length >= 3) ...[
                  _header(context, _onlineSource,
                      _loadingOnline ? '' : '${_online.length}'),
                  if (_loadingOnline)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_onlineError != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_onlineError!,
                          style: const TextStyle(color: AppColors.warning)),
                    )
                  else if (_online.isEmpty && _lastOnlineQuery == q)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No online results.'),
                    ),
                  ..._online.map((f) => _FoodTile(food: f, onTap: () => _open(f))),
                ] else if (q.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Type at least 3 letters to also search USDA online.'),
                  ),
              ],
            ),
            // ---- Favourites tab ----
            _simpleList(state.favorites,
                'No favourites yet. Tap ♡ on a food to save it here.'),
            // ---- Recent tab ----
            _simpleList(state.recents, 'Foods you log will appear here.'),
          ],
        ),
      ),
    );
  }

  Widget _simpleList(List<FoodItem> foods, String empty) {
    if (foods.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(empty, textAlign: TextAlign.center),
        ),
      );
    }
    return ListView(
      children: foods.map((f) => _FoodTile(food: f, onTap: () => _open(f))).toList(),
    );
  }

  Widget _header(BuildContext context, String title, String count) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
        child: Row(children: [
          Text(title, style: AppText.h2),
          const Spacer(),
          Text(count, style: AppText.small),
        ]),
      );
}

class _FoodTile extends StatelessWidget {
  final FoodItem food;
  final VoidCallback onTap;
  const _FoodTile({required this.food, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final serving = food.forGrams(food.servingGrams);
    final (icon, color) = switch (food.source) {
      FoodSource.local => (Icons.eco_rounded, AppColors.fiber),
      FoodSource.usda => (Icons.public_rounded, AppColors.violet),
      FoodSource.openFoodFacts => (Icons.qr_code_rounded, AppColors.carbs),
      FoodSource.recipe => (Icons.menu_book_rounded, AppColors.fat),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
            child: Row(children: [
              IconBadge(icon: icon, color: color, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(food.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (food.brand != null && food.brand!.isNotEmpty)
                          food.brand!,
                        food.servingLabel,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.small,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('${serving.kcal.round()}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
              const Text(' kcal', style: AppText.small),
            ]),
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/food.dart';
import '../models/nutrients.dart';

/// Online food databases:
///  * USDA FoodData Central: generic foods search (needs a free API key).
///  * Open Food Facts: packaged foods by barcode (no key needed).
class FoodApi {
  /// Public demo key: about 30 requests per hour per IP.
  /// Get your own free key at https://fdc.nal.usda.gov/api-key-signup
  /// and paste it here to remove the limit.
  static const usdaApiKey = 'DEMO_KEY';

  static const _timeout = Duration(seconds: 12);
  static const _userAgent = 'NutriSmart/1.0 (Flutter student app)';

  // USDA nutrient ids
  static const _kcal = 1008, _kcalAtwaterGeneral = 2047, _kcalAtwaterSpecific = 2048;
  static const _protein = 1003, _fat = 1004, _carbs = 1005, _fiber = 1079;
  static const _sugars = 2000, _sugarsAlt = 1063;
  static const _sodium = 1093, _iron = 1089, _vitC = 1162, _calcium = 1087;

  static Future<List<FoodItem>> searchUsda(String query) async {
    Uri build({bool filtered = true}) =>
        Uri.https('api.nal.usda.gov', '/fdc/v1/foods/search', {
          'query': query,
          'pageSize': '25',
          if (filtered) 'dataType': 'Foundation,SR Legacy,Survey (FNDDS)',
          'api_key': usdaApiKey,
        });
    var res = await http.get(build()).timeout(_timeout);
    if (res.statusCode == 400) {
      // Some queries are rejected with the data-type filter; retry without it.
      res = await http.get(build(filtered: false)).timeout(_timeout);
    }
    if (res.statusCode != 200) {
      debugPrint('USDA ${res.statusCode}: ${res.body.length > 300 ? res.body.substring(0, 300) : res.body}');
    }
    if (res.statusCode == 429) {
      throw FoodApiException(
          'USDA rate limit reached. Try again later or add your own API key.');
    }
    if (res.statusCode != 200) {
      throw FoodApiException('USDA search failed (${res.statusCode}).');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final foods = (body['foods'] as List? ?? []).cast<Map<String, dynamic>>();

    return foods.map((f) {
      final values = <int, double>{};
      for (final n in (f['foodNutrients'] as List? ?? [])) {
        final id = (n['nutrientId'] as num?)?.toInt();
        final v = (n['value'] as num?)?.toDouble();
        if (id != null && v != null) values[id] = v;
      }
      final kcal = values[_kcal] ??
          values[_kcalAtwaterGeneral] ??
          values[_kcalAtwaterSpecific] ??
          0;
      return FoodItem(
        id: 'usda_${f['fdcId']}',
        name: _titleCase(f['description'] as String? ?? 'Unknown food'),
        brand: f['brandOwner'] as String?,
        source: FoodSource.usda,
        // FoodData Central search values are per 100 g.
        per100g: Nutrients(
          kcal: kcal,
          protein: values[_protein] ?? 0,
          carbs: values[_carbs] ?? 0,
          fat: values[_fat] ?? 0,
          fiber: values[_fiber] ?? 0,
          sugar: values[_sugars] ?? values[_sugarsAlt] ?? 0,
          sodium: values[_sodium] ?? 0,
          iron: values[_iron] ?? 0,
          vitaminC: values[_vitC] ?? 0,
          calcium: values[_calcium] ?? 0,
        ),
      );
    }).where((f) => f.per100g.kcal > 0).toList();
  }

  /// Text search on Open Food Facts (packaged foods). Used as a fallback when
  /// the USDA search is unavailable.
  static Future<List<FoodItem>> searchOpenFoodFacts(String query) async {
    final uri = Uri.https('world.openfoodfacts.org', '/cgi/search.pl', {
      'search_terms': query,
      'search_simple': '1',
      'json': '1',
      'page_size': '20',
      'fields': 'code,product_name,brands,nutriments,serving_quantity,serving_size',
    });
    final res = await http
        .get(uri, headers: {'User-Agent': _userAgent}).timeout(_timeout);
    if (res.statusCode != 200) {
      throw FoodApiException('Online search failed (${res.statusCode}).');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final products = (body['products'] as List? ?? []).cast<Map<String, dynamic>>();
    return products
        .map((p) => _fromOffProduct(p, '${p['code'] ?? p.hashCode}'))
        .where((f) => f.per100g.kcal > 0 && !f.name.startsWith('Product '))
        .toList();
  }

  /// Looks up a packaged product by its barcode on Open Food Facts.
  /// Returns null when the product is not in the database.
  static Future<FoodItem?> lookupBarcode(String barcode) async {
    final uri = Uri.https(
      'world.openfoodfacts.org',
      '/api/v2/product/$barcode.json',
      {'fields': 'product_name,brands,nutriments,serving_quantity,serving_size'},
    );
    final res = await http
        .get(uri, headers: {'User-Agent': _userAgent}).timeout(_timeout);
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) {
      throw FoodApiException('Barcode lookup failed (${res.statusCode}).');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['status'] != 1 || body['product'] == null) return null;
    return _fromOffProduct(body['product'] as Map<String, dynamic>, barcode);
  }

  static FoodItem _fromOffProduct(Map<String, dynamic> p, String barcode) {
    final n = (p['nutriments'] as Map?)?.cast<String, dynamic>() ?? {};

    double g(String key) {
      final v = n[key];
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    var kcal = g('energy-kcal_100g');
    if (kcal == 0) kcal = g('energy_100g') / 4.184; // kJ -> kcal

    final servingQty = (p['serving_quantity'] is num)
        ? (p['serving_quantity'] as num).toDouble()
        : double.tryParse('${p['serving_quantity'] ?? ''}');

    final name = (p['product_name'] as String?)?.trim();
    return FoodItem(
      id: 'off_$barcode',
      name: (name == null || name.isEmpty) ? 'Product $barcode' : name,
      brand: (p['brands'] as String?)?.split(',').first.trim(),
      source: FoodSource.openFoodFacts,
      per100g: Nutrients(
        kcal: kcal,
        protein: g('proteins_100g'),
        carbs: g('carbohydrates_100g'),
        fat: g('fat_100g'),
        fiber: g('fiber_100g'),
        sugar: g('sugars_100g'),
        // Open Food Facts stores minerals in grams; convert to mg.
        sodium: g('sodium_100g') * 1000,
        iron: g('iron_100g') * 1000,
        vitaminC: g('vitamin-c_100g') * 1000,
        calcium: g('calcium_100g') * 1000,
      ),
      servingGrams: (servingQty != null && servingQty > 0) ? servingQty : 100,
      servingLabel: (p['serving_size'] as String?) ?? '100 g',
    );
  }

  static String _titleCase(String s) {
    final lower = s.toLowerCase();
    return lower.isEmpty ? lower : lower[0].toUpperCase() + lower.substring(1);
  }
}

class FoodApiException implements Exception {
  final String message;
  FoodApiException(this.message);
  @override
  String toString() => message;
}

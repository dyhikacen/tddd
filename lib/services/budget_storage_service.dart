import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Storage service handling offline-first local persistence using SharedPreferences.
class BudgetStorageService {
  static const String _kWeeklyBudgetKey = 'mamny_weekly_budget_v1';
  static const String _kLockedNeedsKey = 'mamny_locked_needs_v1';
  static const String _kImpulseItemsKey = 'mamny_impulse_items_v1';

  final SharedPreferences? _prefsInstance;

  BudgetStorageService({SharedPreferences? prefs}) : _prefsInstance = prefs;

  Future<SharedPreferences> _getPrefs() async {
    return _prefsInstance ?? await SharedPreferences.getInstance();
  }

  // ==================== Weekly Budget ====================

  Future<void> saveWeeklyBudget(WeeklyBudget budget) async {
    final prefs = await _getPrefs();
    await prefs.setString(_kWeeklyBudgetKey, budget.toJson());
  }

  Future<WeeklyBudget?> loadWeeklyBudget() async {
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_kWeeklyBudgetKey);
    if (jsonStr == null || jsonStr.isEmpty) return null;

    try {
      return WeeklyBudget.fromJson(jsonStr);
    } catch (_) {
      return null;
    }
  }

  // ==================== Locked Needs ====================

  Future<void> saveLockedNeeds(List<LockedNeedItem> items) async {
    final prefs = await _getPrefs();
    final list = items.map((e) => e.toMap()).toList();
    await prefs.setString(_kLockedNeedsKey, json.encode(list));
  }

  Future<List<LockedNeedItem>> loadLockedNeeds() async {
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_kLockedNeedsKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];

    try {
      final decoded = json.decode(jsonStr) as List<dynamic>;
      return decoded
          .map((e) => LockedNeedItem.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ==================== Impulse Items ====================

  Future<void> saveImpulseItems(List<ImpulseItem> items) async {
    final prefs = await _getPrefs();
    final list = items.map((e) => e.toMap()).toList();
    await prefs.setString(_kImpulseItemsKey, json.encode(list));
  }

  Future<List<ImpulseItem>> loadImpulseItems() async {
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_kImpulseItemsKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];

    try {
      final decoded = json.decode(jsonStr) as List<dynamic>;
      return decoded
          .map((e) => ImpulseItem.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ==================== Clear Storage ====================

  Future<void> clearAll() async {
    final prefs = await _getPrefs();
    await prefs.remove(_kWeeklyBudgetKey);
    await prefs.remove(_kLockedNeedsKey);
    await prefs.remove(_kImpulseItemsKey);
  }
}

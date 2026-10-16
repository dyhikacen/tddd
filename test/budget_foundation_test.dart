import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mamny/models/models.dart';
import 'package:mamny/providers/budget_provider.dart';
import 'package:mamny/services/budget_storage_service.dart';
import 'package:mamny/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Model Serialization & Deserialization Tests', () {
    test('WeeklyBudget toMap and fromMap works correctly', () {
      final now = DateTime(2026, 10, 16);
      final budget = WeeklyBudget(
        id: 'wb-1',
        weekStartDate: now,
        totalIncome: 700000,
        lockedSavingAmount: 100000,
        manualFreeBalanceAdjustment: -15000,
      );

      final map = budget.toMap();
      expect(map['id'], 'wb-1');
      expect(map['totalIncome'], 700000);
      expect(map['lockedSavingAmount'], 100000);
      expect(map['manualFreeBalanceAdjustment'], -15000);

      final reconstructed = WeeklyBudget.fromMap(map);
      expect(reconstructed, budget);
      expect(reconstructed.effectiveManualAdjustment, -15000);

      final jsonStr = budget.toJson();
      final fromJsonBudget = WeeklyBudget.fromJson(jsonStr);
      expect(fromJsonBudget, budget);
    });

    test('LockedNeedItem toMap and fromMap works correctly', () {
      const item = LockedNeedItem(
        id: 'ln-1',
        title: 'Galon & Gas Kos',
        amount: 35000,
        isPaid: false,
      );

      final map = item.toMap();
      expect(map['title'], 'Galon & Gas Kos');
      expect(map['amount'], 35000);
      expect(map['isPaid'], false);

      final fromMap = LockedNeedItem.fromMap(map);
      expect(fromMap, item);

      final updated = item.copyWith(isPaid: true);
      expect(updated.isPaid, true);
      expect(updated.amount, 35000);
    });

    test('ImpulseItem toMap and fromMap works correctly', () {
      final date = DateTime(2026, 10, 16, 12, 0);
      final item = ImpulseItem(
        id: 'imp-1',
        name: 'Kopi Susu Kekinian',
        price: 25000,
        isTemporaryPleasure: true,
        reason: 'Pengen nongkrong pas gabut sore',
        createdAt: date,
        isCompleted: false,
      );

      final map = item.toMap();
      expect(map['name'], 'Kopi Susu Kekinian');
      expect(map['isTemporaryPleasure'], true);
      expect(map['isCompleted'], false);

      final fromMap = ImpulseItem.fromMap(map);
      expect(fromMap, item);

      final toggled = item.copyWith(isCompleted: true);
      expect(toggled.isCompleted, true);
    });
  });

  group('BudgetProvider Business Logic & Automatic Calculation Tests', () {
    late BudgetProvider provider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      final storage = BudgetStorageService();
      provider = BudgetProvider(
        storageService: storage,
        initialBudget: WeeklyBudget(
          id: 'test-budget',
          weekStartDate: DateTime(2026, 10, 16),
          totalIncome: 1000000, // Rp 1.000.000
          lockedSavingAmount: 200000, // Rp 200.000 tabungan terkunci
          manualFreeBalanceAdjustment: null,
        ),
      );
    });

    test('Automated calculations match specified formulas', () async {
      // Free play balance before any locked needs:
      // totalIncome (1.000.000) - lockedNeeds (0) - lockedSaving (200.000) = 800.000
      expect(provider.totalLockedNeeds, 0);
      expect(provider.freePlayBalance, 800000);
      expect(provider.effectiveFreePlayBalance, 800000);

      // Add LockedNeedItems
      await provider.addLockedNeed(const LockedNeedItem(
        id: 'n-1',
        title: 'Makan Pokok Seminggu',
        amount: 300000,
        isPaid: false,
      ));
      await provider.addLockedNeed(const LockedNeedItem(
        id: 'n-2',
        title: 'Laundry Kiloan',
        amount: 50000,
        isPaid: false,
      ));
      await provider.addLockedNeed(const LockedNeedItem(
        id: 'n-3',
        title: 'Galon Air Minum',
        amount: 20000,
        isPaid: false,
      ));

      // totalLockedNeeds should be 300.000 + 50.000 + 20.000 = 370.000
      expect(provider.totalLockedNeeds, 370000);

      // freePlayBalance = 1.000.000 - 370.000 - 200.000 = 430.000
      expect(provider.freePlayBalance, 430000);
      expect(provider.effectiveFreePlayBalance, 430000);

      // With manual wallet adjustment (e.g. user counts -30.000 remaining discrepancy)
      await provider.updateManualAdjustment(-30000);
      expect(provider.freePlayBalance, 430000);
      expect(provider.effectiveFreePlayBalance, 400000);

      // Toggle paid status
      expect(provider.totalPaidLockedNeeds, 0);
      expect(provider.totalUnpaidLockedNeeds, 370000);

      await provider.toggleLockedNeedPaid('n-3');
      expect(provider.totalPaidLockedNeeds, 20000);
      expect(provider.totalUnpaidLockedNeeds, 350000);
      // totalLockedNeeds remains the sum of all locked needs
      expect(provider.totalLockedNeeds, 370000);

      // Delete a locked need
      await provider.deleteLockedNeed('n-2');
      expect(provider.totalLockedNeeds, 320000);
      expect(provider.freePlayBalance, 480000);
    });

    test('ImpulseItem operations: add, toggle completion, and delete', () async {
      final item1 = ImpulseItem(
        id: 'imp-1',
        name: 'Boba Brown Sugar',
        price: 28000,
        isTemporaryPleasure: true,
        reason: 'Mood booster siang',
        createdAt: DateTime.now(),
      );

      final item2 = ImpulseItem(
        id: 'imp-2',
        name: 'Buku Catatan Kuliah',
        price: 15000,
        isTemporaryPleasure: false,
        reason: 'Buku lama sudah penuh',
        createdAt: DateTime.now(),
      );

      await provider.addImpulseItem(item1);
      await provider.addImpulseItem(item2);

      expect(provider.impulseItems.length, 2);
      expect(provider.totalImpulseExpenses, 43000);
      expect(provider.totalTemporaryPleasureExpenses, 28000);
      expect(provider.totalRealNeedImpulseExpenses, 15000);

      // Mark completed / struck through
      expect(provider.impulseItems.first.isCompleted, false);
      await provider.toggleImpulseItemCompletion('imp-1');
      expect(provider.impulseItems.firstWhere((i) => i.id == 'imp-1').isCompleted, true);

      // Delete item
      await provider.deleteImpulseItem('imp-2');
      expect(provider.impulseItems.length, 1);
      expect(provider.impulseItems.first.id, 'imp-1');
    });
  });

  group('Design System Tokens Test', () {
    test('AppColors and AppSpacing match specifications', () {
      expect(AppColors.background.toARGB32(), 0xFFF8F9FA);
      expect(AppColors.surface.toARGB32(), 0xFFFFFFFF);
      expect(AppColors.border.toARGB32(), 0xFFE2E8F0);
      expect(AppColors.textPrimary.toARGB32(), 0xFF0F172A);
      expect(AppColors.textSecondary.toARGB32(), 0xFF475569);
      expect(AppColors.accent.toARGB32(), 0xFF0D9488);
      expect(AppColors.danger.toARGB32(), 0xFFE11D48);
      expect(AppColors.dangerBadgeBg.toARGB32(), 0xFFFFE4E6);

      expect(AppSpacing.screenPaddingValue, 20.0);
      expect(AppSpacing.elementSpacingValue, 16.0);
      expect(AppSpacing.radiusValue, 12.0);

      final theme = AppTheme.lightTheme;
      expect(theme.cardTheme.elevation, 0);
      expect(theme.scaffoldBackgroundColor, AppColors.background);
    });
  });
}

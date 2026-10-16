import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mamny/main.dart';
import 'package:mamny/providers/budget_provider.dart';
import 'package:mamny/models/models.dart';
import 'package:mamny/core/utils/currency_helper.dart';

void main() {
  group('CurrencyHelper Tests', () {
    test('CurrencyHelper formats positive, zero, and negative rupiah correctly', () {
      expect(CurrencyHelper.format(150000), 'Rp 150.000');
      expect(CurrencyHelper.format(0), 'Rp 0');
      expect(CurrencyHelper.format(1000000), 'Rp 1.000.000');
      expect(CurrencyHelper.format(-25000), '-Rp 25.000');
    });

    test('CurrencyHelper parses user input strings reliably', () {
      expect(CurrencyHelper.parse('150.000'), 150000);
      expect(CurrencyHelper.parse('Rp 200.000'), 200000);
      expect(CurrencyHelper.parse('50000'), 50000);
      expect(CurrencyHelper.parse(''), null);
      expect(CurrencyHelper.parse(null), null);
    });
  });

  group('DashboardScreen UI & Interaction Tests', () {
    testWidgets('DashboardScreen renders all 4 visual hierarchy priorities without overflow',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      final testProvider = BudgetProvider(
        initialBudget: WeeklyBudget(
          id: 'wb-test',
          weekStartDate: DateTime.now(),
          totalIncome: 800000,
          lockedSavingAmount: 100000,
        ),
      );

      // Add two locked needs so total is distinct from individual items
      await testProvider.addLockedNeed(
        const LockedNeedItem(
          id: 'need-test-1',
          title: 'Galon Air Minum',
          amount: 20000,
          isPaid: false,
        ),
      );
      await testProvider.addLockedNeed(
        const LockedNeedItem(
          id: 'need-test-2',
          title: 'Laundry Kiloan',
          amount: 30000,
          isPaid: false,
        ),
      );

      // Add impulse items (1 pleasure, 1 need)
      await testProvider.addImpulseItem(
        ImpulseItem(
          id: 'imp-test-1',
          name: 'Kopi Susu Gula Aren',
          price: 24000,
          isTemporaryPleasure: true,
          reason: 'Lagi bosan sore',
          createdAt: DateTime.now(),
        ),
      );
      await testProvider.addImpulseItem(
        ImpulseItem(
          id: 'imp-test-2',
          name: 'Buku Kuliah',
          price: 60000,
          isTemporaryPleasure: false,
          reason: 'Tugas kuliah',
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(MamnyApp(provider: testProvider));
      await tester.pumpAndSettle();

      // On launch dialog appears because imp-test-1 is a temporary pleasure
      expect(find.text('Peringatan Kesenangan Sementara!'), findsOneWidget);
      // Dismiss dialog using "Tahan Dulu (Masih Dipikirin)"
      await tester.tap(find.text('Tahan Dulu (Masih Dipikirin)'));
      await tester.pumpAndSettle();

      // Header title & action
      expect(find.text('Uang Kos Minggu Ini'), findsOneWidget);
      expect(find.text('Atur Minggu Ini'), findsOneWidget);

      // PRIORITAS 1 (Hero Card):
      expect(find.text('SISA JATAH JAJAN BEBAS'), findsOneWidget);
      // 800.000 - 50.000 (locked needs) - 100.000 (saving) = 650.000
      expect(find.text('Rp 650.000'), findsOneWidget);
      expect(find.text('Update Sisa Dompet'), findsOneWidget);

      // PRIORITAS 2 (Ringkasan Dana Terkunci 50:50):
      expect(find.text('Kebutuhan Terkunci'), findsOneWidget);
      expect(find.text('Rp 50.000'), findsOneWidget);
      expect(find.text('Target Tabungan'), findsOneWidget);
      expect(find.text('Rp 100.000'), findsOneWidget);

      // PRIORITAS 3 (Checklist Kebutuhan Terkunci):
      expect(find.text('Checklist Kebutuhan Kos'), findsOneWidget);
      expect(find.text('Galon Air Minum'), findsOneWidget);
      expect(find.text('Rp 20.000'), findsOneWidget);
      expect(find.text('Laundry Kiloan'), findsOneWidget);
      expect(find.text('Rp 30.000'), findsOneWidget);

      // PRIORITAS 4 (Catatan Kebutuhan vs Kesenangan):
      expect(find.text('Catatan Kebutuhan vs Kesenangan'), findsOneWidget);
      expect(find.text('Kesenangan Sementara'), findsOneWidget);
      expect(find.text('Kebutuhan Nyata'), findsOneWidget);
      expect(find.text('Kopi Susu Gula Aren'), findsOneWidget);
      expect(find.text('Buku Kuliah'), findsOneWidget);

      // Test Floating Action Button
      expect(find.text('+ Pikirin Dulu'), findsOneWidget);

      // Test interaction: click Checkbox to mark first need paid
      final checkboxFinders = find.byType(Checkbox);
      expect(checkboxFinders, findsNWidgets(2));
      await tester.tap(checkboxFinders.first);
      await tester.pumpAndSettle();

      expect(testProvider.lockedNeeds.first.isPaid, true);
      expect(find.text('1 dari 2 lunas'), findsOneWidget);

      // Test interaction: click "Update Sisa Dompet" opens modal
      await tester.tap(find.text('Update Sisa Dompet'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Ketikkan total uang tunai & e-wallet yang Anda pegang saat ini. Aplikasi akan langsung menghitung selisihnya.',
        ),
        findsOneWidget,
      );
      expect(find.text('Simpan Sisa Uang'), findsOneWidget);
      await tester.tap(find.text('Simpan Sisa Uang'));
      await tester.pumpAndSettle();
    });

    testWidgets('WeeklySetupSheet opens, updates budget and needs, and reflects on Dashboard',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      final testProvider = BudgetProvider(
        initialBudget: WeeklyBudget(
          id: 'wb-test-2',
          weekStartDate: DateTime.now(),
          totalIncome: 500000,
          lockedSavingAmount: 50000,
        ),
      );

      await tester.pumpWidget(MamnyApp(provider: testProvider));
      await tester.pumpAndSettle();

      // Tap "Atur Minggu Ini" in AppBar
      await tester.tap(find.text('Atur Minggu Ini'));
      await tester.pumpAndSettle();

      expect(find.text('Setup Uang Mingguan'), findsOneWidget);
      expect(find.text('1. UANG MASUK MINGGU INI'), findsOneWidget);
      expect(find.text('2. TARGET TABUNGAN YANG DIKUNCI'), findsOneWidget);
      expect(find.text('3. KEBUTUHAN WAJIB KOS'), findsOneWidget);

      // Tap first quick suggestion chip: "+ Makan Pokok (7 Hari)"
      final chipFinder = find.text('+ Makan Pokok (7 Hari)');
      await tester.ensureVisible(chipFinder);
      await tester.pumpAndSettle();
      await tester.tap(chipFinder);
      await tester.pumpAndSettle();

      expect(find.text('Makan Pokok (7 Hari)'), findsOneWidget);

      // Ensure save button is visible and tap it
      final saveButton = find.text('Simpan Setup Minggu Ini');
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Dashboard reflects the changes (total locked needs and item row)
      expect(find.text('Makan Pokok (7 Hari)'), findsOneWidget);
      expect(find.text('Rp 280.000'), findsNWidgets(2));
    });

    testWidgets('AddImpulseSheet opens via FAB and adds an impulse item with real-time update',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      final testProvider = BudgetProvider(
        initialBudget: WeeklyBudget(
          id: 'wb-test-3',
          weekStartDate: DateTime.now(),
          totalIncome: 600000,
          lockedSavingAmount: 50000,
        ),
      );

      await tester.pumpWidget(MamnyApp(provider: testProvider));
      await tester.pumpAndSettle();

      // Tap FAB "+ Pikirin Dulu"
      await tester.tap(find.text('+ Pikirin Dulu'));
      await tester.pumpAndSettle();

      expect(find.text('Pikirin Dulu (Impulse Filter)'), findsOneWidget);
      expect(find.text('Benar Dibutuhkan'), findsOneWidget);
      expect(find.text('Kesenangan Sementara'), findsOneWidget);

      // Tap a quick suggestion chip: "+ Kopi Kekinian"
      final coffeeChip = find.text('+ Kopi Kekinian');
      expect(coffeeChip, findsOneWidget);
      await tester.tap(coffeeChip);
      await tester.pumpAndSettle();

      // Ensure save button is visible and tap it
      final saveImpulseButton = find.text('Simpan ke "Pikirin Dulu" (Tahan Diri)');
      await tester.ensureVisible(saveImpulseButton);
      await tester.pumpAndSettle();
      await tester.tap(saveImpulseButton);
      await tester.pumpAndSettle();

      // Verify item appears on Dashboard
      expect(find.text('Kopi Kekinian'), findsOneWidget);
      expect(find.text('Rp 25.000'), findsOneWidget);
    });

    testWidgets('On-Launch Warning Dialog shows impact, allows deleting items, and shows appreciation SnackBar',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      final testProvider = BudgetProvider(
        initialBudget: WeeklyBudget(
          id: 'wb-test-warning',
          weekStartDate: DateTime.now(),
          totalIncome: 500000,
          lockedSavingAmount: 100000,
        ),
      );

      // Add 2 temporary pleasure items
      await testProvider.addImpulseItem(
        ImpulseItem(
          id: 'pleasure-1',
          name: 'Sepatu Baru Diskon',
          price: 250000,
          isTemporaryPleasure: true,
          reason: 'Lagi promo flash sale',
          createdAt: DateTime.now(),
        ),
      );
      await testProvider.addImpulseItem(
        ImpulseItem(
          id: 'pleasure-2',
          name: 'Boba Premium',
          price: 30000,
          isTemporaryPleasure: true,
          reason: 'Mau manis-manis',
          createdAt: DateTime.now(),
        ),
      );

      // Launch App
      await tester.pumpWidget(MamnyApp(provider: testProvider));
      await tester.pumpAndSettle();

      // Dialog appears automatically on launch
      expect(find.text('Peringatan Kesenangan Sementara!'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.text('Sepatu Baru Diskon'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.text('Boba Premium'),
        ),
        findsOneWidget,
      );
      expect(find.text('Total Kesenangan Sementara:'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.text('Rp 280.000'),
        ),
        findsOneWidget,
      );

      // Tap "Coret Semua (Gak Jadi Beli)"
      await tester.tap(find.text('Coret Semua (Gak Jadi Beli)'));
      await tester.pumpAndSettle();

      // Dialog is dismissed
      expect(find.text('Peringatan Kesenangan Sementara!'), findsNothing);

      // SnackBar apresiasi appears
      expect(
        find.text(
          'Keputusan bijak! Kamu berhasil menahan lapar mata dan mengamankan tabungan kosmu! 🎉',
        ),
        findsOneWidget,
      );

      // Provider has no remaining temporary pleasure items
      expect(
        testProvider.impulseItems.where((i) => i.isTemporaryPleasure),
        isEmpty,
      );
    });
  });
}

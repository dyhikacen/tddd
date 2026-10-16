import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/budget_storage_service.dart';

/// State management for "Manajemen Uang Kos" (offline-first).
///
/// Automatically calculates:
/// - [totalLockedNeeds]: total of all locked living expenses
/// - [freePlayBalance]: [totalIncome] - [totalLockedNeeds] - [lockedSavingAmount]
/// - [effectiveFreePlayBalance]: [freePlayBalance] adjusted with [manualFreeBalanceAdjustment]
class BudgetProvider extends ChangeNotifier {
  final BudgetStorageService _storageService;

  WeeklyBudget _budget;
  List<LockedNeedItem> _lockedNeeds = [];
  List<ImpulseItem> _impulseItems = [];

  bool _isLoading = false;
  bool _hasInitialized = false;
  String? _errorMessage;

  BudgetProvider({
    BudgetStorageService? storageService,
    WeeklyBudget? initialBudget,
  })  : _storageService = storageService ?? BudgetStorageService(),
        _budget = initialBudget ??
            WeeklyBudget(
              id: 'budget_${DateTime.now().millisecondsSinceEpoch}',
              weekStartDate: DateTime.now(),
              totalIncome: 0,
              lockedSavingAmount: 0,
              manualFreeBalanceAdjustment: null,
            );

  // ==================== Getters ====================

  WeeklyBudget get budget => _budget;
  List<LockedNeedItem> get lockedNeeds => List.unmodifiable(_lockedNeeds);
  List<ImpulseItem> get impulseItems => List.unmodifiable(_impulseItems);

  bool get isLoading => _isLoading;
  bool get hasInitialized => _hasInitialized;
  String? get errorMessage => _errorMessage;

  // ==================== Automated Calculations ====================

  /// Jumlah nominal semua LockedNeedItem (kebutuhan terkunci)
  int get totalLockedNeeds =>
      _lockedNeeds.fold<int>(0, (sum, item) => sum + item.amount);

  /// Jumlah kebutuhan yang sudah dibayar
  int get totalPaidLockedNeeds => _lockedNeeds
      .where((item) => item.isPaid)
      .fold<int>(0, (sum, item) => sum + item.amount);

  /// Jumlah kebutuhan yang belum dibayar
  int get totalUnpaidLockedNeeds => _lockedNeeds
      .where((item) => !item.isPaid)
      .fold<int>(0, (sum, item) => sum + item.amount);

  /// Uang Bebas Main (Formula: totalIncome - totalLockedNeeds - lockedSavingAmount)
  int get freePlayBalance =>
      _budget.totalIncome - totalLockedNeeds - _budget.lockedSavingAmount;

  /// Uang Bebas Main yang sudah disesuaikan dengan adjustment manual di dompet jika ada
  int get effectiveFreePlayBalance =>
      freePlayBalance + _budget.effectiveManualAdjustment;

  /// Total pengeluaran pada daftar impulsif
  int get totalImpulseExpenses =>
      _impulseItems.fold<int>(0, (sum, item) => sum + item.price);

  /// Total pengeluaran impulsif yang dikategorikan "Kesenangan Sementara"
  int get totalTemporaryPleasureExpenses => _impulseItems
      .where((item) => item.isTemporaryPleasure)
      .fold<int>(0, (sum, item) => sum + item.price);

  /// Total pengeluaran impulsif yang ternyata kebutuhan nyata
  int get totalRealNeedImpulseExpenses => _impulseItems
      .where((item) => !item.isTemporaryPleasure)
      .fold<int>(0, (sum, item) => sum + item.price);

  // ==================== Initialization & Persistence ====================

  /// Memuat data dari penyimpanan lokal saat startup
  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final savedBudget = await _storageService.loadWeeklyBudget();
      final savedLockedNeeds = await _storageService.loadLockedNeeds();
      final savedImpulseItems = await _storageService.loadImpulseItems();

      if (savedBudget != null) {
        _budget = savedBudget;
      }
      _lockedNeeds = savedLockedNeeds;
      _impulseItems = savedImpulseItems;
      _hasInitialized = true;

      // Seed data awal jika belum pernah ada data tersimpan sama sekali
      if (savedBudget == null &&
          _lockedNeeds.isEmpty &&
          _impulseItems.isEmpty &&
          _budget.totalIncome == 0) {
        await seedDefaultSampleData();
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat data lokal: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mengisi data contoh awal anak kos (mempermudah demonstrasi & penggunaan pertama)
  Future<void> seedDefaultSampleData() async {
    _budget = WeeklyBudget(
      id: 'budget_${DateTime.now().millisecondsSinceEpoch}',
      weekStartDate: DateTime.now(),
      totalIncome: 750000,
      lockedSavingAmount: 100000,
      manualFreeBalanceAdjustment: null,
    );
    _lockedNeeds = const [
      LockedNeedItem(
        id: 'need_1',
        title: 'Makan Pokok Harian (7 Hari)',
        amount: 280000,
        isPaid: false,
      ),
      LockedNeedItem(
        id: 'need_2',
        title: 'Laundry Kiloan',
        amount: 35000,
        isPaid: true,
      ),
      LockedNeedItem(
        id: 'need_3',
        title: 'Galon Air Minum',
        amount: 20000,
        isPaid: true,
      ),
      LockedNeedItem(
        id: 'need_4',
        title: 'Iuran Sampah & WiFi Kos',
        amount: 50000,
        isPaid: false,
      ),
    ];
    _impulseItems = [
      ImpulseItem(
        id: 'imp_1',
        name: 'Kopi Susu Gula Aren Kekinian',
        price: 24000,
        isTemporaryPleasure: true,
        reason: 'Pengen jajan pas nongkrong sore',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        isCompleted: false,
      ),
      ImpulseItem(
        id: 'imp_2',
        name: 'Buku Modul Praktikum',
        price: 35000,
        isTemporaryPleasure: false,
        reason: 'Bahan kuliah wajib minggu ini',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isCompleted: false,
      ),
    ];
    await _storageService.saveWeeklyBudget(_budget);
    await _storageService.saveLockedNeeds(_lockedNeeds);
    await _storageService.saveImpulseItems(_impulseItems);
    notifyListeners();
  }

  // ==================== WeeklyBudget Actions ====================

  /// Memperbarui seluruh konfigurasi budget mingguan
  Future<void> updateWeeklyBudget(WeeklyBudget newBudget) async {
    _budget = newBudget;
    notifyListeners();
    await _storageService.saveWeeklyBudget(_budget);
  }

  /// Memperbarui total pemasukan mingguan
  Future<void> updateTotalIncome(int totalIncome) async {
    _budget = _budget.copyWith(totalIncome: totalIncome);
    notifyListeners();
    await _storageService.saveWeeklyBudget(_budget);
  }

  /// Memperbarui nominal tabungan yang dikunci
  Future<void> updateLockedSavingAmount(int lockedSavingAmount) async {
    _budget = _budget.copyWith(lockedSavingAmount: lockedSavingAmount);
    notifyListeners();
    await _storageService.saveWeeklyBudget(_budget);
  }

  /// Memperbarui penyesuaian saldo manual (sisa uang fisik di dompet)
  Future<void> updateManualAdjustment(int? adjustment) async {
    _budget = adjustment == null
        ? _budget.copyWith(clearManualAdjustment: true)
        : _budget.copyWith(manualFreeBalanceAdjustment: adjustment);
    notifyListeners();
    await _storageService.saveWeeklyBudget(_budget);
  }

  // ==================== LockedNeedItem Actions ====================

  /// Menambahkan kebutuhan terkunci baru
  Future<void> addLockedNeed(LockedNeedItem item) async {
    _lockedNeeds = [..._lockedNeeds, item];
    notifyListeners();
    await _storageService.saveLockedNeeds(_lockedNeeds);
  }

  /// Menghapus kebutuhan terkunci berdasarkan id
  Future<void> deleteLockedNeed(String id) async {
    _lockedNeeds = _lockedNeeds.where((item) => item.id != id).toList();
    notifyListeners();
    await _storageService.saveLockedNeeds(_lockedNeeds);
  }

  /// Mengubah status pembayaran kebutuhan terkunci (lunas/belum)
  Future<void> toggleLockedNeedPaid(String id) async {
    _lockedNeeds = _lockedNeeds.map((item) {
      if (item.id == id) {
        return item.copyWith(isPaid: !item.isPaid);
      }
      return item;
    }).toList();
    notifyListeners();
    await _storageService.saveLockedNeeds(_lockedNeeds);
  }

  /// Memperbarui data kebutuhan terkunci yang sudah ada
  Future<void> updateLockedNeed(LockedNeedItem updatedItem) async {
    _lockedNeeds = _lockedNeeds.map((item) {
      return item.id == updatedItem.id ? updatedItem : item;
    }).toList();
    notifyListeners();
    await _storageService.saveLockedNeeds(_lockedNeeds);
  }

  // ==================== ImpulseItem Actions ====================

  /// Menambahkan item impulsif baru ke daftar
  Future<void> addImpulseItem(ImpulseItem item) async {
    _impulseItems = [..._impulseItems, item];
    notifyListeners();
    await _storageService.saveImpulseItems(_impulseItems);
  }

  /// Menghapus / mencoret item impulsif dari daftar
  Future<void> deleteImpulseItem(String id) async {
    _impulseItems = _impulseItems.where((item) => item.id != id).toList();
    notifyListeners();
    await _storageService.saveImpulseItems(_impulseItems);
  }

  /// Menandai selesai (atau toggle status selesai/coret) pada item impulsif
  Future<void> toggleImpulseItemCompletion(String id) async {
    _impulseItems = _impulseItems.map((item) {
      if (item.id == id) {
        return item.copyWith(isCompleted: !item.isCompleted);
      }
      return item;
    }).toList();
    notifyListeners();
    await _storageService.saveImpulseItems(_impulseItems);
  }

  /// Menandai item impulsif secara eksplisit selesai / belum
  Future<void> markImpulseItemCompleted(String id, bool completed) async {
    _impulseItems = _impulseItems.map((item) {
      if (item.id == id) {
        return item.copyWith(isCompleted: completed);
      }
      return item;
    }).toList();
    notifyListeners();
    await _storageService.saveImpulseItems(_impulseItems);
  }

  /// Memperbarui detail item impulsif
  Future<void> updateImpulseItem(ImpulseItem updatedItem) async {
    _impulseItems = _impulseItems.map((item) {
      return item.id == updatedItem.id ? updatedItem : item;
    }).toList();
    notifyListeners();
    await _storageService.saveImpulseItems(_impulseItems);
  }

  /// Menghapus semua item impulsif yang berstatus kesenangan sementara
  Future<void> deleteAllTemporaryPleasureItems() async {
    _impulseItems =
        _impulseItems.where((item) => !item.isTemporaryPleasure).toList();
    notifyListeners();
    await _storageService.saveImpulseItems(_impulseItems);
  }

  /// Reset semua data untuk pengujian atau siklus baru
  Future<void> resetAll() async {
    _budget = WeeklyBudget(
      id: 'budget_${DateTime.now().millisecondsSinceEpoch}',
      weekStartDate: DateTime.now(),
      totalIncome: 0,
      lockedSavingAmount: 0,
    );
    _lockedNeeds = [];
    _impulseItems = [];
    notifyListeners();
    await _storageService.clearAll();
  }
}

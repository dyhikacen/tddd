import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/currency_helper.dart';
import '../models/models.dart';
import '../providers/budget_provider.dart';

/// Modal Bottom Sheet untuk mengatur uang masuk, tabungan terkunci,
/// dan daftar kebutuhan wajib mingguan anak kos.
class WeeklySetupSheet extends StatefulWidget {
  final BudgetProvider provider;

  const WeeklySetupSheet({super.key, required this.provider});

  /// Method statis untuk membuka modal dengan konfigurasi responsif & nyaman.
  static Future<void> show(BuildContext context, BudgetProvider provider) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => WeeklySetupSheet(provider: provider),
    );
  }

  @override
  State<WeeklySetupSheet> createState() => _WeeklySetupSheetState();
}

class _WeeklySetupSheetState extends State<WeeklySetupSheet> {
  late final TextEditingController _incomeController;
  late final TextEditingController _savingController;
  final TextEditingController _needTitleController = TextEditingController();
  final TextEditingController _needAmountController = TextEditingController();

  late List<LockedNeedItem> _editableNeeds;

  // Template cepat kebutuhan anak kos (minim ketikan)
  static const List<Map<String, dynamic>> _quickNeedTemplates = [
    {'title': 'Makan Pokok (7 Hari)', 'amount': 280000},
    {'title': 'Laundry Kiloan', 'amount': 35000},
    {'title': 'Galon Air Minum', 'amount': 20000},
    {'title': 'Listrik / Token', 'amount': 50000},
    {'title': 'WiFi & Sampah Kos', 'amount': 40000},
  ];

  @override
  void initState() {
    super.initState();
    final budget = widget.provider.budget;
    _incomeController = TextEditingController(
      text: budget.totalIncome > 0
          ? CurrencyHelper.formatWithoutPrefix(budget.totalIncome)
          : '',
    );
    _savingController = TextEditingController(
      text: budget.lockedSavingAmount > 0
          ? CurrencyHelper.formatWithoutPrefix(budget.lockedSavingAmount)
          : '',
    );
    _editableNeeds = List.from(widget.provider.lockedNeeds);

    _incomeController.addListener(_onFieldChanged);
    _savingController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _savingController.dispose();
    _needTitleController.dispose();
    _needAmountController.dispose();
    super.dispose();
  }

  int get _parsedIncome => CurrencyHelper.parse(_incomeController.text) ?? 0;
  int get _parsedSaving => CurrencyHelper.parse(_savingController.text) ?? 0;
  int get _totalNeeds =>
      _editableNeeds.fold<int>(0, (sum, item) => sum + item.amount);
  int get _previewFreeBalance => _parsedIncome - _totalNeeds - _parsedSaving;

  void _addNewNeed(String title, int amount) {
    if (title.trim().isEmpty || amount <= 0) return;
    setState(() {
      _editableNeeds.add(
        LockedNeedItem(
          id: 'need_${DateTime.now().millisecondsSinceEpoch}_${_editableNeeds.length}',
          title: title.trim(),
          amount: amount,
          isPaid: false,
        ),
      );
      _needTitleController.clear();
      _needAmountController.clear();
    });
  }

  void _removeNeed(int index) {
    setState(() {
      _editableNeeds.removeAt(index);
    });
  }

  Future<void> _saveAll() async {
    final updatedBudget = widget.provider.budget.copyWith(
      totalIncome: _parsedIncome,
      lockedSavingAmount: _parsedSaving,
    );

    await widget.provider.updateWeeklyBudget(updatedBudget);

    // Sinkronisasi kebutuhan terkunci
    final currentProviderNeeds = widget.provider.lockedNeeds;
    for (final need in currentProviderNeeds) {
      if (!_editableNeeds.any((e) => e.id == need.id)) {
        await widget.provider.deleteLockedNeed(need.id);
      }
    }
    for (final need in _editableNeeds) {
      if (!currentProviderNeeds.any((e) => e.id == need.id)) {
        await widget.provider.addLockedNeed(need);
      } else {
        await widget.provider.updateLockedNeed(need);
      }
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      child: Column(
        children: [
          // Header Sheet
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Setup Uang Mingguan',
                        style: AppTypography.sectionTitle,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Kunci dana wajib agar jatah jajan bebas aman',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Body Form
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // INPUT 1: UANG MASUK MINGGU INI
                  const Text(
                    '1. UANG MASUK MINGGU INI',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Total kiriman orang tua, gaji, atau saldo awal minggu.',
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _incomeController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      prefixText: 'Rp ',
                      prefixStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      hintText: 'Contoh: 750.000',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // INPUT 2: TARGET TABUNGAN TERKUNCI
                  const Text(
                    '2. TARGET TABUNGAN YANG DIKUNCI',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Dana yang diamankan di awal dan dilarang disentuh.',
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _savingController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentDark,
                    ),
                    decoration: const InputDecoration(
                      prefixText: 'Rp ',
                      prefixStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentDark,
                      ),
                      hintText: 'Contoh: 100.000',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // INPUT 3: KELOLA KEBUTUHAN WAJIB MINGGUAN
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '3. KEBUTUHAN WAJIB KOS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Text(
                        'Total: ${CurrencyHelper.format(_totalNeeds)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Kebutuhan pokok tanpa kompromi (Makan, Galon, Laundry).',
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: 10),

                  // Quick Suggestion Chips (Minim Ketikan)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _quickNeedTemplates.map((template) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ActionChip(
                            backgroundColor: AppColors.background,
                            side: const BorderSide(
                              color: AppColors.border,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            label: Text(
                              '+ ${template['title']}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            onPressed: () {
                              _addNewNeed(
                                template['title'] as String,
                                template['amount'] as int,
                              );
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Daftar Item Kebutuhan Saat Ini
                  if (_editableNeeds.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: AppSpacing.radius12,
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: const Center(
                        child: Text(
                          'Belum ada kebutuhan wajib. Tambahkan di bawah atau klik chip template di atas.',
                          textAlign: TextAlign.center,
                          style: AppTypography.caption,
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppSpacing.radius12,
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _editableNeeds.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _editableNeeds[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14.0,
                              vertical: 10.0,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Text(
                                  CurrencyHelper.format(item.amount),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline_rounded,
                                    size: 18,
                                    color: AppColors.danger,
                                  ),
                                  onPressed: () => _removeNeed(index),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Form Input Tambah Manual
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: AppSpacing.radius12,
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _needTitleController,
                                style: const TextStyle(fontSize: 14),
                                decoration: const InputDecoration(
                                  hintText: 'Nama kebutuhan baru',
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _needAmountController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 14),
                                decoration: const InputDecoration(
                                  hintText: 'Biaya (Rp)',
                                  prefixText: 'Rp ',
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppColors.accent,
                                width: 1,
                              ),
                              foregroundColor: AppColors.accent,
                            ),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text(
                              '+ Tambah ke Daftar Kebutuhan',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: () {
                              final title = _needTitleController.text.trim();
                              final amount = CurrencyHelper.parse(
                                    _needAmountController.text,
                                  ) ??
                                  0;
                              _addNewNeed(title, amount);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // LIVE PREVIEW HASIL KALKULASI SISA UANG BEBAS
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _previewFreeBalance < 0
                          ? AppColors.dangerBadgeBg
                          : AppColors.accentBackground,
                      borderRadius: AppSpacing.radius12,
                      border: Border.all(
                        color: _previewFreeBalance < 0
                            ? const Color(0xFFFECDD3)
                            : AppColors.accentLight,
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'SIMULASI SISA JATAH JAJAN:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            Text(
                              CurrencyHelper.format(_previewFreeBalance),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _previewFreeBalance < 0
                                    ? AppColors.danger
                                    : AppColors.accentDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _previewFreeBalance < 0
                              ? 'Peringatan: Kebutuhan & tabungan melebihi uang masuk!'
                              : 'Uang ini murni bebas Anda pakai tanpa khawatir kehabisan makan.',
                          style: TextStyle(
                            fontSize: 12,
                            color: _previewFreeBalance < 0
                                ? AppColors.dangerText
                                : AppColors.accentDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // TOMBOL SIMPAN UTAMA (Minimal tinggi 48px)
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: AppSpacing.shapeRounded12,
                      ),
                      onPressed: _saveAll,
                      child: const Text(
                        'Simpan Setup Minggu Ini',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 48,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Batal',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

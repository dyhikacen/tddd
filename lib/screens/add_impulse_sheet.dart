import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/currency_helper.dart';
import '../models/models.dart';
import '../providers/budget_provider.dart';

/// Modal Bottom Sheet "Pikirin Dulu (Impulse Filter)"
/// Membantu anak kos mengevaluasi pembelian impulsif dengan filter kejujuran
/// sebelum mengeluarkan uang jajan.
class AddImpulseSheet extends StatefulWidget {
  final BudgetProvider provider;

  const AddImpulseSheet({super.key, required this.provider});

  /// Method statis untuk membuka modal dengan mudah
  static Future<void> show(BuildContext context, BudgetProvider provider) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => AddImpulseSheet(provider: provider),
    );
  }

  @override
  State<AddImpulseSheet> createState() => _AddImpulseSheetState();
}

class _AddImpulseSheetState extends State<AddImpulseSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  // Default: Kesenangan Sementara (filter refleksi diri anak kos)
  bool _isTemporaryPleasure = true;

  // Template cepat barang yang sering bikin lapar mata (minim ketikan)
  static const List<Map<String, dynamic>> _quickImpulseSuggestions = [
    {'name': 'Kopi Kekinian', 'price': 25000, 'isPleasure': true},
    {'name': 'Boba / Minuman Manis', 'price': 22000, 'isPleasure': true},
    {'name': 'Baju / Kaos Baru', 'price': 85000, 'isPleasure': true},
    {'name': 'Buku / Modul Kuliah', 'price': 45000, 'isPleasure': false},
    {'name': 'Obat / Vitamin', 'price': 30000, 'isPleasure': false},
  ];

  // Template alasan cepat (minim ketikan)
  static const List<String> _quickReasonSuggestions = [
    'Lagi jenuh / butuh reward',
    'Barang habis & wajib dipakai',
    'Ada diskon / FOMO sesaat',
    'Kebutuhan mendesak tugas kuliah',
  ];

  @override
  void initState() {
    super.initState();
    _priceController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  int get _parsedPrice => CurrencyHelper.parse(_priceController.text) ?? 0;
  int get _currentFreeBalance => widget.provider.effectiveFreePlayBalance;
  int get _balanceAfterPurchase => _currentFreeBalance - _parsedPrice;

  void _applySuggestion(Map<String, dynamic> item) {
    setState(() {
      _nameController.text = item['name'] as String;
      _priceController.text =
          CurrencyHelper.formatWithoutPrefix(item['price'] as int);
      _isTemporaryPleasure = item['isPleasure'] as bool;
    });
  }

  void _applyReason(String reason) {
    setState(() {
      _reasonController.text = reason;
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final price = _parsedPrice;

    if (name.isEmpty || price <= 0) return;

    final newItem = ImpulseItem(
      id: 'imp_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      price: price,
      isTemporaryPleasure: _isTemporaryPleasure,
      reason: _reasonController.text.trim(),
      createdAt: DateTime.now(),
      isCompleted: false,
    );

    await widget.provider.addImpulseItem(newItem);

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
          // Header
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
                        'Pikirin Dulu (Impulse Filter)',
                        style: AppTypography.sectionTitle,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Jeda sejenak sebelum checkout / beli barang',
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
                  // Chips Barang Sering Tergoda (Minim Ketikan)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _quickImpulseSuggestions.map((item) {
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
                              '+ ${item['name']}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            onPressed: () => _applySuggestion(item),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // INPUT NAMA BARANG
                  const Text(
                    'NAMA BARANG / JAJAN',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    autofocus: true,
                    style: const TextStyle(fontSize: 15),
                    decoration: const InputDecoration(
                      hintText: 'Contoh: Kopi Susu, Baju Vintage, Sepatu',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // INPUT HARGA BARANG
                  const Text(
                    'PERKIRAAN HARGA',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _priceController,
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
                      hintText: 'Contoh: 25.000',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // PILIHAN KATEGORI: 2 TOMBOL KONTRAS TINGGI (BUKAN DROPDOWN)
                  const Text(
                    'KATEGORI KEJUJURAN DIRI',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Jujur pada diri sendiri sebelum mengeluarkan uang jatah jajanmu.',
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      // PILIHAN A: BENAR DIBUTUHKAN (NEED) -> TEAL
                      Expanded(
                        child: InkWell(
                          onTap: () =>
                              setState(() => _isTemporaryPleasure = false),
                          borderRadius: AppSpacing.radius12,
                          child: Container(
                            height: 60,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: !_isTemporaryPleasure
                                  ? AppColors.accentBackground
                                  : AppColors.surface,
                              borderRadius: AppSpacing.radius12,
                              border: Border.all(
                                color: !_isTemporaryPleasure
                                    ? AppColors.accent
                                    : AppColors.border,
                                width: !_isTemporaryPleasure ? 2.0 : 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  !_isTemporaryPleasure
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  size: 18,
                                  color: !_isTemporaryPleasure
                                      ? AppColors.accent
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Benar Dibutuhkan',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: !_isTemporaryPleasure
                                              ? AppColors.accentDark
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '(Need / Wajib)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: !_isTemporaryPleasure
                                              ? AppColors.accentDark
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // PILIHAN B: KESENANGAN SEMENTARA (WANT) -> CORAL RED
                      Expanded(
                        child: InkWell(
                          onTap: () =>
                              setState(() => _isTemporaryPleasure = true),
                          borderRadius: AppSpacing.radius12,
                          child: Container(
                            height: 60,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: _isTemporaryPleasure
                                  ? AppColors.dangerBadgeBg
                                  : AppColors.surface,
                              borderRadius: AppSpacing.radius12,
                              border: Border.all(
                                color: _isTemporaryPleasure
                                    ? AppColors.danger
                                    : AppColors.border,
                                width: _isTemporaryPleasure ? 2.0 : 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isTemporaryPleasure
                                      ? Icons.warning_amber_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  size: 18,
                                  color: _isTemporaryPleasure
                                      ? AppColors.danger
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Kesenangan Sementara',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: _isTemporaryPleasure
                                              ? AppColors.dangerText
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '(Want / Lapar Mata)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _isTemporaryPleasure
                                              ? AppColors.dangerText
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // INPUT ALASAN SINGKAT
                  const Text(
                    'REFLEKSI: KENAPA MERASA HARUS BELI SEKARANG?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tuliskan alasan jujur untuk dibaca ulang nanti.',
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reasonController,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      hintText:
                          'Contoh: Karena lagi lelah tugas / karena memang baju kuliah robek...',
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Chips Alasan Cepat (Minim Ketikan)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _quickReasonSuggestions.map((reason) {
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
                              reason,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            onPressed: () => _applyReason(reason),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // IMPACT CHECK: SISA UANG SETELAH BELI INI
                  if (_parsedPrice > 0)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _balanceAfterPurchase < 0
                            ? AppColors.dangerBadgeBg
                            : AppColors.background,
                        borderRadius: AppSpacing.radius12,
                        border: Border.all(
                          color: _balanceAfterPurchase < 0
                              ? const Color(0xFFFECDD3)
                              : AppColors.border,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dampak ke Sisa Uang Jajan:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Saat ini: ${CurrencyHelper.format(_currentFreeBalance)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: AppColors.textTertiary,
                              ),
                              Text(
                                'Sisa: ${CurrencyHelper.format(_balanceAfterPurchase)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _balanceAfterPurchase < 0
                                      ? AppColors.danger
                                      : AppColors.accentDark,
                                ),
                              ),
                            ],
                          ),
                          if (_balanceAfterPurchase < 0) ...[
                            const SizedBox(height: 4),
                            const Text(
                              'Peringatan: Pembelian ini akan membuat uang jajanmu minus!',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.dangerText,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // TOMBOL SIMPAN KE DAFTAR PIKIRIN DULU (Minimal tinggi 48px)
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isTemporaryPleasure
                            ? AppColors.textPrimary
                            : AppColors.accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: AppSpacing.shapeRounded12,
                      ),
                      onPressed: _save,
                      child: Text(
                        _isTemporaryPleasure
                            ? 'Simpan ke "Pikirin Dulu" (Tahan Diri)'
                            : 'Catat Kebutuhan Ini',
                        style: const TextStyle(
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
                      child: const Text('Batal', style: TextStyle(fontSize: 14)),
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

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/currency_helper.dart';
import '../models/models.dart';
import '../providers/budget_provider.dart';
import 'weekly_setup_sheet.dart';
import 'add_impulse_sheet.dart';

/// Layar Utama Dashboard "Manajemen Uang Kos" (Mamny).
/// Menerapkan aturan Flat Minimalist tanpa gradasi dengan hierarki visual terarah.
class DashboardScreen extends StatefulWidget {
  final BudgetProvider provider;

  const DashboardScreen({super.key, required this.provider});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Flag agar dialog peringatan hanya muncul 1 kali setiap sesi aplikasi dibuka
  bool _hasShownWarningDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowLaunchWarning();
    });
  }

  void _checkAndShowLaunchWarning() {
    if (_hasShownWarningDialog || !mounted) return;

    if (widget.provider.isLoading) {
      void listener() {
        if (!widget.provider.isLoading && mounted) {
          widget.provider.removeListener(listener);
          _checkAndShowLaunchWarning();
        }
      }
      widget.provider.addListener(listener);
      return;
    }

    final activePleasureItems = widget.provider.impulseItems
        .where((item) => item.isTemporaryPleasure && !item.isCompleted)
        .toList();

    if (activePleasureItems.isNotEmpty) {
      _hasShownWarningDialog = true;
      _showTemporaryPleasureWarningDialog(context, widget.provider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border, width: 1.0),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/images/homny_logo.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'HoMny',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Uang Kos Minggu Ini',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.accent, width: 1.0),
                foregroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: AppSpacing.shapeRounded12,
              ),
              onPressed: () => WeeklySetupSheet.show(context, provider),
              icon: const Icon(Icons.tune_rounded, size: 16),
              label: const Text(
                'Atur Minggu Ini',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: provider,
          builder: (context, _) {
            if (provider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              );
            }

            return SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // PRIORITAS 1: HERO CARD (Sisa Jatah Jajan Bebas)
                  _buildHeroCard(context, provider),
                  const SizedBox(height: 20),

                  // PRIORITAS 2: RINGKASAN DANA TERKUNCI (Row 50:50 Simetris)
                  _buildLockedFundsSummary(context, provider),
                  const SizedBox(height: 24),

                  // PRIORITAS 3: CHECKLIST KEBUTUHAN TERKUNCI
                  _buildLockedNeedsSection(context, provider),
                  const SizedBox(height: 24),

                  // PRIORITAS 4: PREVIEW KEBUTUHAN VS KESENANGAN
                  _buildImpulseWishlistSection(context, provider),
                  const SizedBox(height: 24),

                  // FOOTER BRANDING
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.asset(
                            'assets/images/homny_logo.png',
                            width: 16,
                            height: 16,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'HoMny • Manajemen Uang Kos Cerdas',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddImpulseSheet.show(context, provider),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: AppSpacing.shapeRounded12,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          '+ Pikirin Dulu',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // PRIORITAS 1: HERO CARD
  // ===========================================================================
  Widget _buildHeroCard(BuildContext context, BudgetProvider provider) {
    final effectiveBalance = provider.effectiveFreePlayBalance;
    final hasAdjustment = provider.budget.manualFreeBalanceAdjustment != null;
    final adjustmentValue = provider.budget.effectiveManualAdjustment;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.radius12,
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SISA JATAH JAJAN BEBAS',
                style: AppTypography.caption,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentBackground,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.accentLight, width: 1),
                ),
                child: const Text(
                  'Aman Dipakai',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Nominal utama font paling besar (28sp, Bold)
          Text(
            CurrencyHelper.format(effectiveBalance),
            style: AppTypography.mainAmount.copyWith(
              color: effectiveBalance < 0
                  ? AppColors.danger
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),

          // Status & Info Penyesuaian
          if (hasAdjustment)
            Row(
              children: [
                Icon(
                  adjustmentValue >= 0
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 14,
                  color: adjustmentValue >= 0
                      ? AppColors.accent
                      : AppColors.danger,
                ),
                const SizedBox(width: 4),
                Text(
                  'Disesuaikan fisik dompet (${adjustmentValue >= 0 ? '+' : ''}${CurrencyHelper.format(adjustmentValue)})',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            )
          else
            const Text(
              'Otomatis terhitung dari pemasukan dikurangi dana wajib.',
              style: AppTypography.caption,
            ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Tombol kecil "Update Sisa Dompet"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Malas catat harian? Cukup sesuaikan sisa uang di dompet Anda.',
                  style: AppTypography.caption.copyWith(fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _showUpdateWalletDialog(context, provider),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  side: const BorderSide(color: AppColors.accent, width: 1),
                  foregroundColor: AppColors.accent,
                ),
                icon: const Icon(Icons.account_balance_wallet_outlined, size: 16),
                label: const Text(
                  'Update Sisa Dompet',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // PRIORITAS 2: RINGKASAN DANA TERKUNCI (Row Simetris 50:50)
  // ===========================================================================
  Widget _buildLockedFundsSummary(
    BuildContext context,
    BudgetProvider provider,
  ) {
    final paidCount = provider.lockedNeeds.where((i) => i.isPaid).length;
    final totalCount = provider.lockedNeeds.length;

    return Row(
      children: [
        // Kotak A: Kebutuhan Kos Terkunci
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppSpacing.radius12,
              border: Border.all(color: AppColors.border, width: 1.0),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Kebutuhan Terkunci',
                      style: AppTypography.caption,
                    ),
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  CurrencyHelper.format(provider.totalLockedNeeds),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: paidCount == totalCount && totalCount > 0
                        ? AppColors.successBadgeBg
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: paidCount == totalCount && totalCount > 0
                          ? AppColors.accentLight
                          : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    totalCount == 0
                        ? '0 Item'
                        : '$paidCount dari $totalCount lunas',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: paidCount == totalCount && totalCount > 0
                          ? AppColors.successText
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Kotak B: Target Tabungan Mingguan
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppSpacing.radius12,
              border: Border.all(color: AppColors.border, width: 1.0),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Target Tabungan',
                      style: AppTypography.caption,
                    ),
                    const Icon(
                      Icons.savings_outlined,
                      size: 16,
                      color: AppColors.accent,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  CurrencyHelper.format(provider.budget.lockedSavingAmount),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentBackground,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.accentLight, width: 1),
                  ),
                  child: const Text(
                    'Diamankan di awal',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // PRIORITAS 3: CHECKLIST KEBUTUHAN TERKUNCI
  // ===========================================================================
  Widget _buildLockedNeedsSection(
    BuildContext context,
    BudgetProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Checklist Kebutuhan Kos',
                    style: AppTypography.sectionTitle,
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Cukup klik centang bila sudah dibayar minggu ini',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => _showAddLockedNeedDialog(context, provider),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'Tambah',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (provider.lockedNeeds.isEmpty)
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppSpacing.radius12,
              border: Border.all(color: AppColors.border, width: 1.0),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.playlist_add_check_rounded,
                    size: 36,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Belum ada kebutuhan terkunci.',
                    style: AppTypography.bodySecondary,
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () =>
                        _showAddLockedNeedDialog(context, provider),
                    child: const Text('+ Tambah (Galon, Laundry, Makan)'),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppSpacing.radius12,
              border: Border.all(color: AppColors.border, width: 1.0),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.lockedNeeds.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = provider.lockedNeeds[index];
                return InkWell(
                  onTap: () => provider.toggleLockedNeedPaid(item.id),
                  borderRadius: index == 0
                      ? const BorderRadius.vertical(top: Radius.circular(12))
                      : index == provider.lockedNeeds.length - 1
                          ? const BorderRadius.vertical(
                              bottom: Radius.circular(12))
                          : BorderRadius.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      children: [
                        // Checkbox Flat
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: item.isPaid,
                            activeColor: AppColors.accent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            side: const BorderSide(
                              color: AppColors.textTertiary,
                              width: 1.5,
                            ),
                            onChanged: (_) =>
                                provider.toggleLockedNeedPaid(item.id),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Title & Status
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: AppTypography.body.copyWith(
                                  decoration: item.isPaid
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: item.isPaid
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.isPaid
                                    ? 'Sudah dibayar'
                                    : 'Belum dibayar minggu ini',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: item.isPaid
                                      ? AppColors.accent
                                      : AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Nominal
                        Text(
                          CurrencyHelper.format(item.amount),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: item.isPaid
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            decoration: item.isPaid
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),

                        // Delete button
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.textTertiary,
                          ),
                          onPressed: () => provider.deleteLockedNeed(item.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // ===========================================================================
  // PRIORITAS 4: PREVIEW KEBUTUHAN VS KESENANGAN
  // ===========================================================================
  Widget _buildImpulseWishlistSection(
    BuildContext context,
    BudgetProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Catatan Kebutuhan vs Kesenangan',
                    style: AppTypography.sectionTitle,
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Pikirkan sebelum beli: Kesenangan atau Kebutuhan?',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => AddImpulseSheet.show(context, provider),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'Tambah',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (provider.impulseItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppSpacing.radius12,
              border: Border.all(color: AppColors.border, width: 1.0),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 36,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Belum ada catatan barang yang sedang dipikirkan.',
                    style: AppTypography.bodySecondary,
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => AddImpulseSheet.show(context, provider),
                    child: const Text('+ Catat Keinginan Baru'),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: provider.impulseItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = provider.impulseItems[index];
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppSpacing.radius12,
                  border: Border.all(color: AppColors.border, width: 1.0),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge Tag Kategori (Merah solid kontras untuk Kesenangan Sementara)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: item.isTemporaryPleasure
                                ? AppColors.dangerBadgeBg
                                : AppColors.successBadgeBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: item.isTemporaryPleasure
                                  ? const Color(0xFFFECDD3)
                                  : AppColors.accentLight,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            item.isTemporaryPleasure
                                ? 'Kesenangan Sementara'
                                : 'Kebutuhan Nyata',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: item.isTemporaryPleasure
                                  ? AppColors.dangerText
                                  : AppColors.successText,
                            ),
                          ),
                        ),
                        const Spacer(),

                        // Nominal
                        Text(
                          CurrencyHelper.format(item.price),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: item.isCompleted
                                ? AppColors.textTertiary
                                : AppColors.textPrimary,
                            decoration: item.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Nama Barang
                    Text(
                      item.name,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: item.isCompleted
                            ? AppColors.textTertiary
                            : AppColors.textPrimary,
                        decoration: item.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Alasan
                    if (item.reason.isNotEmpty)
                      Text(
                        'Alasan: "${item.reason}"',
                        style: AppTypography.caption.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                      ),

                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 8),

                    // Aksi (Coret / Tandai Batal / Hapus)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () =>
                              provider.toggleImpulseItemCompletion(item.id),
                          icon: Icon(
                            item.isCompleted
                                ? Icons.undo_rounded
                                : Icons.check_circle_outline_rounded,
                            size: 16,
                            color: item.isCompleted
                                ? AppColors.textSecondary
                                : AppColors.accent,
                          ),
                          label: Text(
                            item.isCompleted
                                ? 'Batal Coret'
                                : 'Tandai Selesai / Coret',
                            style: TextStyle(
                              fontSize: 12,
                              color: item.isCompleted
                                  ? AppColors.textSecondary
                                  : AppColors.accent,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Hapus Item',
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: AppColors.textTertiary,
                          ),
                          onPressed: () =>
                              provider.deleteImpulseItem(item.id),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // ===========================================================================
  // DIALOGS & BOTTOM SHEETS
  // ===========================================================================

  /// Dialog untuk pengguna yang ingin mengupdate sisa uang di dompet secara cepat
  void _showUpdateWalletDialog(BuildContext context, BudgetProvider provider) {
    final controller = TextEditingController(
      text: provider.budget.manualFreeBalanceAdjustment != null
          ? CurrencyHelper.formatWithoutPrefix(
              provider.effectiveFreePlayBalance)
          : CurrencyHelper.formatWithoutPrefix(provider.freePlayBalance),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Update Sisa Dompet',
                    style: AppTypography.sectionTitle,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Ketikkan total uang tunai & e-wallet yang Anda pegang saat ini. Aplikasi akan langsung menghitung selisihnya.',
                style: AppTypography.caption,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  prefixText: 'Rp ',
                  prefixStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  hintText: '0',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final parsedValue = CurrencyHelper.parse(controller.text);
                  if (parsedValue != null) {
                    // Selisih = Saldo nyata yang diketik - freePlayBalance bawaan hitungan
                    final adjustment = parsedValue - provider.freePlayBalance;
                    provider.updateManualAdjustment(adjustment);
                  }
                  Navigator.pop(sheetContext);
                },
                child: const Text('Simpan Sisa Uang'),
              ),
              if (provider.budget.manualFreeBalanceAdjustment != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    provider.updateManualAdjustment(null);
                    Navigator.pop(sheetContext);
                  },
                  child: const Text(
                    'Kembalikan ke Hitungan Otomatis',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Dialog untuk menambahkan Kebutuhan Terkunci (Laundry, Galon, Listrik, dll)
  void _showAddLockedNeedDialog(BuildContext context, BudgetProvider provider) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: AppSpacing.shapeRounded12,
          title: const Text(
            'Tambah Kebutuhan Terkunci',
            style: AppTypography.sectionTitle,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nama Kebutuhan',
                  hintText: 'Contoh: Galon, Laundry, WiFi',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nominal Biaya (Rp)',
                  hintText: 'Contoh: 30000',
                  prefixText: 'Rp ',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Batal',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                final amount = CurrencyHelper.parse(amountController.text) ?? 0;
                if (title.isNotEmpty && amount > 0) {
                  provider.addLockedNeed(
                    LockedNeedItem(
                      id: 'need_${DateTime.now().millisecondsSinceEpoch}',
                      title: title,
                      amount: amount,
                      isPaid: false,
                    ),
                  );
                }
                Navigator.pop(dialogContext);
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  /// Dialog Peringatan On-Launch untuk item "Kesenangan Sementara"
  void _showTemporaryPleasureWarningDialog(
    BuildContext context,
    BudgetProvider provider,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return ListenableBuilder(
          listenable: provider,
          builder: (dialogContext, _) {
            final pleasureItems = provider.impulseItems
                .where((item) => item.isTemporaryPleasure && !item.isCompleted)
                .toList();

            // Jika semua item kesenangan sementara dihapus oleh user dari dalam dialog
            if (pleasureItems.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Navigator.canPop(dialogCtx)) {
                  Navigator.pop(dialogCtx);
                  _showCelebrationSnackBar(context);
                }
              });
              return const SizedBox.shrink();
            }

            final totalPleasurePrice =
                pleasureItems.fold<int>(0, (sum, i) => sum + i.price);
            final freePlayBalance = provider.effectiveFreePlayBalance;
            final lockedSaving = provider.budget.lockedSavingAmount;

            final isOverBudget = totalPleasurePrice > freePlayBalance;
            final impactMessage = isOverBudget
                ? 'Sisa jatah jajan bebasmu ${CurrencyHelper.format(freePlayBalance)}, tapi kamu mengincar kesenangan sementara senilai ${CurrencyHelper.format(totalPleasurePrice)}. Kalau dibeli, jatah jajanmu habis & minus ${CurrencyHelper.format(totalPleasurePrice - freePlayBalance)}, serta target tabunganmu sebesar ${CurrencyHelper.format(lockedSaving)} terancam gagal!'
                : 'Sisa jatah jajan bebasmu ${CurrencyHelper.format(freePlayBalance)}, dan kamu mengincar kesenangan sementara senilai ${CurrencyHelper.format(totalPleasurePrice)}. Kalau dibeli, jatah jajanmu tersisa ${CurrencyHelper.format(freePlayBalance - totalPleasurePrice)}. Jangan sampai target tabunganmu sebesar ${CurrencyHelper.format(lockedSaving)} terganggu!';

            return Dialog(
              backgroundColor: AppColors.surface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border, width: 1.0),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Peringatan: Merah Lembut (#FFE4E6) & Teks Merah Tegas (#E11D48)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppColors.dangerBadgeBg,
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFFECDD3),
                            width: 1.0,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFFECDD3),
                                width: 1.0,
                              ),
                            ),
                            child: const Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.danger,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Peringatan Kesenangan Sementara!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.dangerText,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Pikir ulang sebelum jatah jajanmu habis',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content Body
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Box Ringkasan Dampak Finansial
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: AppSpacing.radius12,
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 1.0,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Total Kesenangan Sementara:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        CurrencyHelper.format(
                                            totalPleasurePrice),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.danger,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Divider(height: 1),
                                  const SizedBox(height: 8),
                                  Text(
                                    impactMessage,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: isOverBudget
                                          ? AppColors.dangerText
                                          : AppColors.textPrimary,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Subtitle Daftar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Daftar Barang Lapar Mata:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${pleasureItems.length} item',
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // List Items Kesenangan Sementara
                            Container(
                              constraints:
                                  const BoxConstraints(maxHeight: 180),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: AppSpacing.radius12,
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 1.0,
                                ),
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: pleasureItems.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final item = pleasureItems[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.name,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                item.reason.isNotEmpty
                                                    ? 'Alasan: "${item.reason}"'
                                                    : 'Tidak ada alasan khusus.',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontStyle: FontStyle.italic,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          CurrencyHelper.format(item.price),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.danger,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          tooltip: 'Hapus dari daftar',
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            size: 18,
                                            color: AppColors.textTertiary,
                                          ),
                                          onPressed: () => provider
                                              .deleteImpulseItem(item.id),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Footer Action Buttons (Min-height 48px)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Tombol Utama: Solid Teal #0D9488
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: AppSpacing.shapeRounded12,
                              ),
                              onPressed: () async {
                                Navigator.pop(dialogCtx);
                                await provider
                                    .deleteAllTemporaryPleasureItems();
                                if (context.mounted) {
                                  _showCelebrationSnackBar(context);
                                }
                              },
                              child: const Text(
                                'Coret Semua (Gak Jadi Beli)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Tombol Sekunder: Outlined / Text Button
                          SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: AppColors.border,
                                  width: 1.0,
                                ),
                                foregroundColor: AppColors.textSecondary,
                                shape: AppSpacing.shapeRounded12,
                              ),
                              onPressed: () => Navigator.pop(dialogCtx),
                              child: const Text(
                                'Tahan Dulu (Masih Dipikirin)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCelebrationSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: const Row(
          children: [
            Icon(Icons.stars_rounded, color: AppColors.accentLight),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Keputusan bijak! Kamu berhasil menahan lapar mata dan mengamankan tabungan kosmu! 🎉',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



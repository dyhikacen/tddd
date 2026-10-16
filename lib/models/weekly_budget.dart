import 'dart:convert';

/// Represents a weekly budget cycle for the boarder (anak kos).
///
/// Tracks total income, locked savings, and an optional manual adjustment
/// if the user updates the actual cash/wallet balance.
class WeeklyBudget {
  final String id;
  final DateTime weekStartDate;
  final int totalIncome;
  final int lockedSavingAmount;
  final int? manualFreeBalanceAdjustment;

  const WeeklyBudget({
    required this.id,
    required this.weekStartDate,
    required this.totalIncome,
    required this.lockedSavingAmount,
    this.manualFreeBalanceAdjustment,
  });

  /// Effective manual adjustment value (defaults to 0 if null)
  int get effectiveManualAdjustment => manualFreeBalanceAdjustment ?? 0;

  WeeklyBudget copyWith({
    String? id,
    DateTime? weekStartDate,
    int? totalIncome,
    int? lockedSavingAmount,
    int? manualFreeBalanceAdjustment,
    bool clearManualAdjustment = false,
  }) {
    return WeeklyBudget(
      id: id ?? this.id,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      totalIncome: totalIncome ?? this.totalIncome,
      lockedSavingAmount: lockedSavingAmount ?? this.lockedSavingAmount,
      manualFreeBalanceAdjustment: clearManualAdjustment
          ? null
          : (manualFreeBalanceAdjustment ?? this.manualFreeBalanceAdjustment),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'weekStartDate': weekStartDate.toIso8601String(),
      'totalIncome': totalIncome,
      'lockedSavingAmount': lockedSavingAmount,
      'manualFreeBalanceAdjustment': manualFreeBalanceAdjustment,
    };
  }

  factory WeeklyBudget.fromMap(Map<String, dynamic> map) {
    return WeeklyBudget(
      id: map['id'] as String? ?? '',
      weekStartDate: map['weekStartDate'] != null
          ? DateTime.tryParse(map['weekStartDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      totalIncome: (map['totalIncome'] as num?)?.toInt() ?? 0,
      lockedSavingAmount: (map['lockedSavingAmount'] as num?)?.toInt() ?? 0,
      manualFreeBalanceAdjustment:
          (map['manualFreeBalanceAdjustment'] as num?)?.toInt(),
    );
  }

  String toJson() => json.encode(toMap());

  factory WeeklyBudget.fromJson(String source) =>
      WeeklyBudget.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'WeeklyBudget(id: $id, weekStartDate: $weekStartDate, totalIncome: $totalIncome, lockedSavingAmount: $lockedSavingAmount, manualFreeBalanceAdjustment: $manualFreeBalanceAdjustment)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WeeklyBudget &&
        other.id == id &&
        other.weekStartDate.isAtSameMomentAs(weekStartDate) &&
        other.totalIncome == totalIncome &&
        other.lockedSavingAmount == lockedSavingAmount &&
        other.manualFreeBalanceAdjustment == manualFreeBalanceAdjustment;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        weekStartDate.hashCode ^
        totalIncome.hashCode ^
        lockedSavingAmount.hashCode ^
        manualFreeBalanceAdjustment.hashCode;
  }
}

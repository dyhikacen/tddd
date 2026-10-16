import 'dart:convert';

/// Represents a locked non-negotiable living expense (Kebutuhan Terkunci)
/// such as Laundry, Galon, Kos fee, or Basic Meal allocation.
class LockedNeedItem {
  final String id;
  final String title;
  final int amount;
  final bool isPaid;

  const LockedNeedItem({
    required this.id,
    required this.title,
    required this.amount,
    this.isPaid = false,
  });

  LockedNeedItem copyWith({
    String? id,
    String? title,
    int? amount,
    bool? isPaid,
  }) {
    return LockedNeedItem(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      isPaid: isPaid ?? this.isPaid,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'isPaid': isPaid,
    };
  }

  factory LockedNeedItem.fromMap(Map<String, dynamic> map) {
    return LockedNeedItem(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      isPaid: map['isPaid'] as bool? ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory LockedNeedItem.fromJson(String source) =>
      LockedNeedItem.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'LockedNeedItem(id: $id, title: $title, amount: $amount, isPaid: $isPaid)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LockedNeedItem &&
        other.id == id &&
        other.title == title &&
        other.amount == amount &&
        other.isPaid == isPaid;
  }

  @override
  int get hashCode {
    return id.hashCode ^ title.hashCode ^ amount.hashCode ^ isPaid.hashCode;
  }
}

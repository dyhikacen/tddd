import 'dart:convert';

/// Represents an item on the impulse list / wishlist.
///
/// Categorized into:
/// - Kesenangan Sementara (isTemporaryPleasure: true) - flagged with danger badge
/// - Kebutuhan Nyata (isTemporaryPleasure: false)
///
/// Can be marked completed / struck through or deleted.
class ImpulseItem {
  final String id;
  final String name;
  final int price;
  final bool isTemporaryPleasure;
  final String reason;
  final DateTime createdAt;
  final bool isCompleted;

  const ImpulseItem({
    required this.id,
    required this.name,
    required this.price,
    required this.isTemporaryPleasure,
    required this.reason,
    required this.createdAt,
    this.isCompleted = false,
  });

  ImpulseItem copyWith({
    String? id,
    String? name,
    int? price,
    bool? isTemporaryPleasure,
    String? reason,
    DateTime? createdAt,
    bool? isCompleted,
  }) {
    return ImpulseItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      isTemporaryPleasure: isTemporaryPleasure ?? this.isTemporaryPleasure,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'isTemporaryPleasure': isTemporaryPleasure,
      'reason': reason,
      'createdAt': createdAt.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory ImpulseItem.fromMap(Map<String, dynamic> map) {
    return ImpulseItem(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      price: (map['price'] as num?)?.toInt() ?? 0,
      isTemporaryPleasure: map['isTemporaryPleasure'] as bool? ?? false,
      reason: map['reason'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory ImpulseItem.fromJson(String source) =>
      ImpulseItem.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ImpulseItem(id: $id, name: $name, price: $price, isTemporaryPleasure: $isTemporaryPleasure, reason: $reason, createdAt: $createdAt, isCompleted: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ImpulseItem &&
        other.id == id &&
        other.name == name &&
        other.price == price &&
        other.isTemporaryPleasure == isTemporaryPleasure &&
        other.reason == reason &&
        other.createdAt.isAtSameMomentAs(createdAt) &&
        other.isCompleted == isCompleted;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        price.hashCode ^
        isTemporaryPleasure.hashCode ^
        reason.hashCode ^
        createdAt.hashCode ^
        isCompleted.hashCode;
  }
}

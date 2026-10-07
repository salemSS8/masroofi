/// نموذج ميزانية الظرف المالي (Envelope Budgeting)
class EnvelopeModel {
  final int? id;
  final String name;
  final double allocatedAmount;
  final String icon;
  final int color;
  final double spentAmount; // يتم احتسابه ديناميكياً من مجموع المعاملات المرتبطة

  const EnvelopeModel({
    this.id,
    required this.name,
    required this.allocatedAmount,
    this.icon = 'mail',
    this.color = 0xFF3B82F6,
    this.spentAmount = 0.0,
  });

  /// المبلغ المتبقي داخل الظرف
  double get remainingAmount => allocatedAmount - spentAmount;

  /// نسبة الصرف الحالية (0.0 إلى 1.0+)
  double get spentPercentage {
    if (allocatedAmount <= 0) return 0.0;
    return (spentAmount / allocatedAmount).clamp(0.0, 2.0);
  }

  /// هل تم تجاوز الميزانية المحددة للظرف؟
  bool get isOverBudget => spentAmount > allocatedAmount;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'allocated_amount': allocatedAmount,
      'icon': icon,
      'color': color,
    };
  }

  factory EnvelopeModel.fromMap(Map<String, dynamic> map, {double spent = 0.0}) {
    return EnvelopeModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? 'ظرف',
      allocatedAmount: (map['allocated_amount'] as num?)?.toDouble() ??
          (map['budget'] as num?)?.toDouble() ??
          0.0,
      icon: map['icon'] as String? ?? 'mail',
      color: (map['color'] as num?)?.toInt() ?? 0xFF3B82F6,
      spentAmount: spent > 0
          ? spent
          : ((map['spent'] as num?)?.toDouble() ?? 0.0),
    );
  }

  EnvelopeModel copyWith({
    int? id,
    String? name,
    double? allocatedAmount,
    String? icon,
    int? color,
    double? spentAmount,
  }) {
    return EnvelopeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      allocatedAmount: allocatedAmount ?? this.allocatedAmount,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      spentAmount: spentAmount ?? this.spentAmount,
    );
  }

  @override
  String toString() =>
      'EnvelopeModel(id: $id, name: $name, allocated: $allocatedAmount, spent: $spentAmount)';
}

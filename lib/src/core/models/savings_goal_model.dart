/// نموذج أهداف الادخار المالي (Savings Goal)
class SavingsGoalModel {
  final int? id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final String icon;
  final int color;

  const SavingsGoalModel({
    this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.targetDate,
    this.icon = 'savings',
    this.color = 0xFF10B981,
  });

  /// المبلغ المتبقي لاكتمال الهدف
  double get remainingAmount =>
      (targetAmount - currentAmount).clamp(0.0, double.infinity);

  /// نسبة التقدم الحالية نحو الهدف (0.0 إلى 1.0)
  double get progressPercentage {
    if (targetAmount <= 0) return 0.0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }

  /// هل تم تحقيق الهدف بالكامل؟
  bool get isCompleted => currentAmount >= targetAmount;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'target_date': targetDate?.toIso8601String(),
      'icon': icon,
      'color': color,
    };
  }

  factory SavingsGoalModel.fromMap(Map<String, dynamic> map) {
    return SavingsGoalModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? 'هدف ادخار',
      targetAmount: (map['target_amount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (map['current_amount'] as num?)?.toDouble() ?? 0.0,
      targetDate: map['target_date'] != null
          ? DateTime.tryParse(map['target_date'] as String)
          : null,
      icon: map['icon'] as String? ?? 'savings',
      color: (map['color'] as num?)?.toInt() ?? 0xFF10B981,
    );
  }

  SavingsGoalModel copyWith({
    int? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? icon,
    int? color,
  }) {
    return SavingsGoalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }

  @override
  String toString() =>
      'SavingsGoalModel(id: $id, name: $name, current: $currentAmount, target: $targetAmount)';
}

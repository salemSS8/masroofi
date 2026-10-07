/// نموذج المعاملة الدورية المتكررة (Recurring Transaction)
class RecurringTransactionModel {
  final int? id;
  final String title;
  final double amount;
  final String type; // 'income' or 'expense'
  final int? categoryId;
  final String frequency; // 'daily', 'weekly', 'monthly', 'yearly'
  final int? dayOfMonth;
  final DateTime nextRunDate;
  final bool isActive;

  const RecurringTransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    this.categoryId,
    this.frequency = 'monthly',
    this.dayOfMonth,
    required this.nextRunDate,
    this.isActive = true,
  });

  bool get isDue =>
      isActive && DateTime.now().isAfter(nextRunDate.subtract(const Duration(seconds: 1)));

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'category_id': categoryId,
      'frequency': frequency,
      'day_of_month': dayOfMonth,
      'next_run_date': nextRunDate.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  factory RecurringTransactionModel.fromMap(Map<String, dynamic> map) {
    return RecurringTransactionModel(
      id: map['id'] as int?,
      title: map['title'] as String? ?? 'معاملة دورية',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      type: map['type'] as String? ?? 'expense',
      categoryId: map['category_id'] as int?,
      frequency: map['frequency'] as String? ?? 'monthly',
      dayOfMonth: (map['day_of_month'] as num?)?.toInt(),
      nextRunDate: map['next_run_date'] != null
          ? DateTime.parse(map['next_run_date'] as String)
          : DateTime.now(),
      isActive: (map['is_active'] as int? ?? 1) == 1,
    );
  }

  RecurringTransactionModel copyWith({
    int? id,
    String? title,
    double? amount,
    String? type,
    int? categoryId,
    String? frequency,
    int? dayOfMonth,
    DateTime? nextRunDate,
    bool? isActive,
  }) {
    return RecurringTransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      frequency: frequency ?? this.frequency,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      nextRunDate: nextRunDate ?? this.nextRunDate,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() =>
      'RecurringTransactionModel(id: $id, title: $title, amount: $amount, next: $nextRunDate)';
}

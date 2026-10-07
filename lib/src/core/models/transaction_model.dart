/// نموذج المعاملة المالية (دخل أو مصروف)
class TransactionModel {
  final int? id;
  final String title;
  final double amount;
  final String type; // 'income' or 'expense'
  final int? categoryId;
  final int? envelopeId;
  final DateTime date;
  final String? notes;
  final DateTime createdAt;
  final bool isRecurring;

  // حقول مساعدة إضافية للعرض عند عمل JOIN مع جدول التصنيفات
  final String? categoryName;
  final String? categoryIcon;
  final int? categoryColor;

  const TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    this.categoryId,
    this.envelopeId,
    required this.date,
    this.notes,
    DateTime? createdAt,
    this.isRecurring = false,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  }) : createdAt = createdAt ?? date;

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'category_id': categoryId,
      'envelope_id': envelopeId,
      'date': date.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'is_recurring': isRecurring ? 1 : 0,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    final noteText = map['notes'] as String? ?? map['note'] as String? ?? '';
    final recurringVal = map['is_recurring'];
    final bool isRec = (recurringVal == 1 || recurringVal == true) ||
        noteText.contains('المعاملات المتكررة') ||
        noteText.contains('معاملة دورية') ||
        noteText.toLowerCase().contains('recurring');

    return TransactionModel(
      id: map['id'] as int?,
      title: map['title'] as String? ?? (map['note'] as String? ?? 'معاملة'),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      type: map['type'] as String? ?? 'expense',
      categoryId: map['category_id'] as int?,
      envelopeId: map['envelope_id'] as int?,
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : (map['datetime'] != null
              ? DateTime.parse(map['datetime'] as String)
              : DateTime.now()),
      notes: map['notes'] as String? ?? map['note'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      isRecurring: isRec,
      categoryName: map['category_name'] as String?,
      categoryIcon: map['category_icon'] as String?,
      categoryColor: (map['category_color'] as num?)?.toInt(),
    );
  }

  TransactionModel copyWith({
    int? id,
    String? title,
    double? amount,
    String? type,
    int? categoryId,
    int? envelopeId,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
    bool? isRecurring,
    String? categoryName,
    String? categoryIcon,
    int? categoryColor,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      envelopeId: envelopeId ?? this.envelopeId,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      isRecurring: isRecurring ?? this.isRecurring,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
    );
  }

  @override
  String toString() =>
      'TransactionModel(id: $id, title: $title, amount: $amount, type: $type, date: $date, isRecurring: $isRecurring)';
}

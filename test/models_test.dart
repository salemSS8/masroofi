import 'package:flutter_test/flutter_test.dart';
import 'package:bashnddof/src/core/models/category_model.dart';
import 'package:bashnddof/src/core/models/envelope_model.dart';
import 'package:bashnddof/src/core/models/savings_goal_model.dart';
import 'package:bashnddof/src/core/models/transaction_model.dart';
import 'package:bashnddof/src/core/models/recurring_transaction_model.dart';

void main() {
  group('CategoryModel Tests', () {
    test('toMap and fromMap work correctly', () {
      const cat = CategoryModel(
        id: 1,
        name: 'طعام',
        icon: 'restaurant',
        color: 0xFFEF4444,
        isIncome: false,
      );

      final map = cat.toMap();
      expect(map['name'], 'طعام');
      expect(map['is_income'], 0);

      final from = CategoryModel.fromMap(map);
      expect(from.id, 1);
      expect(from.name, 'طعام');
      expect(from.icon, 'restaurant');
      expect(from.isIncome, false);
    });

    test('copyWith updates fields', () {
      const cat = CategoryModel(id: 1, name: 'طعام');
      final updated = cat.copyWith(name: 'مشروبات', isIncome: true);
      expect(updated.id, 1);
      expect(updated.name, 'مشروبات');
      expect(updated.isIncome, true);
    });
  });

  group('EnvelopeModel Tests', () {
    test('remaining and spent percentage calculations', () {
      const env = EnvelopeModel(
        id: 1,
        name: 'بقالة',
        allocatedAmount: 1000.0,
        spentAmount: 400.0,
      );

      expect(env.remainingAmount, 600.0);
      expect(env.spentPercentage, 0.4);
      expect(env.isOverBudget, false);

      final over = env.copyWith(spentAmount: 1200.0);
      expect(over.remainingAmount, -200.0);
      expect(over.isOverBudget, true);
    });

    test('toMap and fromMap preservation', () {
      const env = EnvelopeModel(
        id: 5,
        name: 'وقود',
        allocatedAmount: 500.0,
        spentAmount: 150.0,
      );

      final map = env.toMap();
      final from = EnvelopeModel.fromMap(map, spent: 150.0);
      expect(from.name, 'وقود');
      expect(from.allocatedAmount, 500.0);
      expect(from.spentAmount, 150.0);
    });
  });

  group('SavingsGoalModel Tests', () {
    test('progress and remaining calculation', () {
      const goal = SavingsGoalModel(
        id: 1,
        name: 'سيارة',
        targetAmount: 50000.0,
        currentAmount: 25000.0,
      );

      expect(goal.progressPercentage, 0.5);
      expect(goal.remainingAmount, 25000.0);
      expect(goal.isCompleted, false);

      final completed = goal.copyWith(currentAmount: 50000.0);
      expect(completed.progressPercentage, 1.0);
      expect(completed.remainingAmount, 0.0);
      expect(completed.isCompleted, true);
    });
  });

  group('TransactionModel Tests', () {
    test('toMap and fromMap preservation', () {
      final now = DateTime(2026, 10, 3, 12, 0);
      final tx = TransactionModel(
        id: 10,
        title: 'شراء بقالة',
        amount: 150.5,
        type: 'expense',
        categoryId: 2,
        envelopeId: 1,
        date: now,
        notes: 'ملاحظة تجريبية',
      );

      expect(tx.isExpense, true);
      expect(tx.isIncome, false);

      final map = tx.toMap();
      final from = TransactionModel.fromMap(map);
      expect(from.id, 10);
      expect(from.title, 'شراء بقالة');
      expect(from.amount, 150.5);
      expect(from.type, 'expense');
      expect(from.categoryId, 2);
      expect(from.envelopeId, 1);
      expect(from.notes, 'ملاحظة تجريبية');
    });
  });

  group('RecurringTransactionModel Tests', () {
    test('isDue and serialization', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 1));
      final recurring = RecurringTransactionModel(
        id: 1,
        title: 'اشتراك إنترنت',
        amount: 100.0,
        type: 'expense',
        frequency: 'monthly',
        nextRunDate: pastDate,
        isActive: true,
      );

      expect(recurring.isDue, true);

      final map = recurring.toMap();
      final from = RecurringTransactionModel.fromMap(map);
      expect(from.title, 'اشتراك إنترنت');
      expect(from.amount, 100.0);
      expect(from.frequency, 'monthly');
    });
  });
}

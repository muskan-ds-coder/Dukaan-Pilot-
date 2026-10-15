import '../entities/expense.dart';

abstract class ExpenseRepository {
  Future<List<Expense>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    int limit = 100,
  });

  Future<Expense?> getExpenseById(String id);
  Future<Expense> createExpense(Expense expense);
  Future<void> deleteExpense(String id);
  Future<int> getTotalExpensesPaise({DateTime? startDate, DateTime? endDate});
  Future<Map<String, int>> getExpensesByCategory({DateTime? startDate, DateTime? endDate});
}

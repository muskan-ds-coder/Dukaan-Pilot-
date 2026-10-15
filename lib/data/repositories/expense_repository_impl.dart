import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../local/database_helper.dart';
import '../models/expense_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final DatabaseHelper _dbHelper;
  final Uuid _uuid = const Uuid();

  ExpenseRepositoryImpl({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<String> _getBusinessId() async {
    final prefs = await SharedPreferences.getInstance();
    final businessId = prefs.getString(AppConstants.keyCurrentBusinessId);
    if (businessId == null) {
      throw const DatabaseFailure('No active business found.');
    }
    return businessId;
  }

  @override
  Future<List<Expense>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    int limit = 100,
  }) async {
    final db = await _dbHelper.database;
    final businessId = await _getBusinessId();

    final whereClauses = <String>['business_id = ?'];
    final whereArgs = <dynamic>[businessId];

    if (category != null && category.isNotEmpty && category != 'ALL') {
      whereClauses.add('category = ?');
      whereArgs.add(category);
    }
    if (startDate != null) {
      whereClauses.add('date >= ?');
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }
    if (endDate != null) {
      whereClauses.add('date <= ?');
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    final rows = await db.query(
      'expenses',
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'date DESC, created_at DESC',
      limit: limit,
    );

    return rows.map((m) => ExpenseModel.fromMap(m)).toList();
  }

  @override
  Future<Expense?> getExpenseById(String id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return ExpenseModel.fromMap(rows.first);
  }

  @override
  Future<Expense> createExpense(Expense expense) async {
    if (expense.amountPaise <= 0) {
      throw const ValidationFailure('Expense amount must be greater than zero.');
    }

    final db = await _dbHelper.database;
    final businessId = await _getBusinessId();
    final id = expense.id.isEmpty ? _uuid.v4() : expense.id;
    final now = DateTime.now();

    final model = ExpenseModel(
      id: id,
      businessId: businessId,
      category: expense.category.trim(),
      amountPaise: expense.amountPaise,
      description: expense.description?.trim(),
      date: expense.date,
      createdAt: now,
      syncStatus: 'PENDING',
    );

    await db.insert('expenses', model.toMap());
    return model;
  }

  @override
  Future<void> deleteExpense(String id) async {
    final db = await _dbHelper.database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<int> getTotalExpensesPaise({DateTime? startDate, DateTime? endDate}) async {
    final db = await _dbHelper.database;
    final businessId = await _getBusinessId();

    final whereClauses = <String>['business_id = ?'];
    final whereArgs = <dynamic>[businessId];

    if (startDate != null) {
      whereClauses.add('date >= ?');
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }
    if (endDate != null) {
      whereClauses.add('date <= ?');
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    final result = await db.rawQuery('''
      SELECT SUM(amount_paise) as total
      FROM expenses
      WHERE ${whereClauses.join(' AND ')}
    ''', whereArgs);

    if (result.isNotEmpty && result.first['total'] != null) {
      return result.first['total'] as int;
    }
    return 0;
  }

  @override
  Future<Map<String, int>> getExpensesByCategory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await _dbHelper.database;
    final businessId = await _getBusinessId();

    final whereClauses = <String>['business_id = ?'];
    final whereArgs = <dynamic>[businessId];

    if (startDate != null) {
      whereClauses.add('date >= ?');
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }
    if (endDate != null) {
      whereClauses.add('date <= ?');
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    final result = await db.rawQuery('''
      SELECT category, SUM(amount_paise) as total
      FROM expenses
      WHERE ${whereClauses.join(' AND ')}
      GROUP BY category
      ORDER BY total DESC
    ''', whereArgs);

    final map = <String, int>{};
    for (final row in result) {
      final cat = row['category'] as String;
      final total = row['total'] as int;
      map[cat] = total;
    }
    return map;
  }
}

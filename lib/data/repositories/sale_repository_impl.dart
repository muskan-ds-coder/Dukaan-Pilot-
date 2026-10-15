import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/sale_repository.dart';
import '../local/database_helper.dart';
import '../models/customer_model.dart';
import '../models/ledger_entry_model.dart';
import '../models/product_model.dart';
import '../models/sale_model.dart';
import '../models/stock_movement_model.dart';

class SaleRepositoryImpl implements SaleRepository {
  final DatabaseHelper _dbHelper;
  final Uuid _uuid = const Uuid();

  SaleRepositoryImpl({DatabaseHelper? dbHelper})
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
  Future<List<Sale>> getSales({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    final db = await _dbHelper.database;
    final businessId = await _getBusinessId();

    final whereClauses = <String>['s.business_id = ?'];
    final whereArgs = <dynamic>[businessId];

    if (startDate != null) {
      whereClauses.add('s.created_at >= ?');
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }
    if (endDate != null) {
      whereClauses.add('s.created_at <= ?');
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    final sql = '''
      SELECT s.*, c.name as customer_name
      FROM sales s
      LEFT JOIN customers c ON s.customer_id = c.id
      WHERE ${whereClauses.join(' AND ')}
      ORDER BY s.created_at DESC
      LIMIT ?
    ''';
    whereArgs.add(limit);

    final saleRows = await db.rawQuery(sql, whereArgs);
    final salesList = <Sale>[];

    for (final row in saleRows) {
      final saleId = row['id'] as String;
      final itemRows = await db.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );
      final items = itemRows.map((m) => SaleItemModel.fromMap(m)).toList();
      salesList.add(SaleModel.fromMap(row, items: items));
    }

    return salesList;
  }

  @override
  Future<Sale?> getSaleById(String id) async {
    final db = await _dbHelper.database;
    final saleRows = await db.rawQuery('''
      SELECT s.*, c.name as customer_name
      FROM sales s
      LEFT JOIN customers c ON s.customer_id = c.id
      WHERE s.id = ?
    ''', [id]);

    if (saleRows.isEmpty) return null;

    final itemRows = await db.query(
      'sale_items',
      where: 'sale_id = ?',
      whereArgs: [id],
    );
    final items = itemRows.map((m) => SaleItemModel.fromMap(m)).toList();
    return SaleModel.fromMap(saleRows.first, items: items);
  }

  @override
  Future<Sale> createSale({
    String? customerId,
    required List<SaleItem> items,
    int discountPaise = 0,
    required String paymentMethod,
    int? receivedAmountPaise,
    int? udhaarAmountPaise,
    String? notes,
  }) async {
    if (items.isEmpty) {
      throw const ValidationFailure('Cannot create sale with zero items.');
    }

    final db = await _dbHelper.database;
    final businessId = await _getBusinessId();
    final saleId = _uuid.v4();
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    // Calculate subtotal
    int subtotalPaise = 0;
    for (final item in items) {
      subtotalPaise += item.subtotalPaise;
    }
    final totalPaise = (subtotalPaise - discountPaise) > 0 ? (subtotalPaise - discountPaise) : 0;

    await db.transaction((txn) async {
      // 1. Insert Sale record
      final saleModel = SaleModel(
        id: saleId,
        businessId: businessId,
        customerId: customerId,
        items: items,
        subtotalPaise: subtotalPaise,
        discountPaise: discountPaise,
        totalPaise: totalPaise,
        paymentMethod: paymentMethod,
        notes: notes,
        createdAt: now,
        syncStatus: 'PENDING',
      );
      await txn.insert('sales', saleModel.toMap());

      // 2. Insert items and atomically decrement stock + record movements
      for (final item in items) {
        final itemModel = SaleItemModel(
          id: _uuid.v4(),
          saleId: saleId,
          productId: item.productId,
          productName: item.productName,
          quantity: item.quantity,
          unitPricePaise: item.unitPricePaise,
          subtotalPaise: item.subtotalPaise,
        );
        await txn.insert('sale_items', itemModel.toMap());

        // Check product stock
        final pQuery = await txn.query(
          'products',
          where: 'id = ?',
          whereArgs: [item.productId],
        );
        if (pQuery.isNotEmpty) {
          final prod = ProductModel.fromMap(pQuery.first);
          final updatedStock = prod.stockQuantity - item.quantity;

          // Record auditable movement
          final movement = StockMovementModel(
            id: _uuid.v4(),
            businessId: businessId,
            productId: item.productId,
            type: AppConstants.movementSale,
            quantity: item.quantity,
            previousStock: prod.stockQuantity,
            newStock: updatedStock,
            referenceId: saleId,
            note: 'Sale #${saleId.substring(0, 8)}',
            createdAt: now,
            syncStatus: 'PENDING',
          );
          await txn.insert('stock_movements', movement.toMap());

          // Update product stock
          await txn.update(
            'products',
            {
              'stock_quantity': updatedStock,
              'updated_at': nowMs,
            },
            where: 'id = ?',
            whereArgs: [item.productId],
          );
        }
      }

      // 3. Handle Credit/Udhaar or Split portion if applicable
      final creditAmount = udhaarAmountPaise ?? (paymentMethod == 'Credit/Udhaar' ? totalPaise : 0);
      if (creditAmount > 0 && customerId != null) {
        final custQuery = await txn.query(
          'customers',
          where: 'id = ?',
          whereArgs: [customerId],
        );
        if (custQuery.isNotEmpty) {
          final cust = CustomerModel.fromMap(custQuery.first);
          final newBal = cust.currentBalancePaise + creditAmount;

          // Insert customer ledger entry
          final ledger = LedgerEntryModel(
            id: _uuid.v4(),
            businessId: businessId,
            customerId: customerId,
            type: AppConstants.ledgerCredit,
            amountPaise: creditAmount,
            referenceId: saleId,
            description: paymentMethod == 'Split Payment'
                ? 'Split sale #${saleId.substring(0, 8)} (Udhaar: ${creditAmount ~/ 100})'
                : 'Credit sale #${saleId.substring(0, 8)}',
            createdAt: now,
            syncStatus: 'PENDING',
          );
          await txn.insert('customer_ledger', ledger.toMap());

          // Update customer current balance
          await txn.update(
            'customers',
            {
              'current_balance_paise': newBal,
              'updated_at': nowMs,
            },
            where: 'id = ?',
            whereArgs: [customerId],
          );
        }
      }
    });

    return getSaleById(saleId).then((val) => val!);
  }

  @override
  Future<int> getTodaySalesTotal() async {
    final db = await _dbHelper.database;
    final businessId = await _getBusinessId();
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;

    final result = await db.rawQuery('''
      SELECT SUM(total_paise) as total
      FROM sales
      WHERE business_id = ? AND created_at >= ?
    ''', [businessId, startOfDay]);

    if (result.isNotEmpty && result.first['total'] != null) {
      return result.first['total'] as int;
    }
    return 0;
  }

  @override
  Future<int> getTodayTransactionCount() async {
    final db = await _dbHelper.database;
    final businessId = await _getBusinessId();
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;

    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM sales
      WHERE business_id = ? AND created_at >= ?
    ''', [businessId, startOfDay]);

    if (result.isNotEmpty && result.first['count'] != null) {
      return result.first['count'] as int;
    }
    return 0;
  }
}

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/purchase.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../local/database_helper.dart';
import '../models/product_model.dart';
import '../models/purchase_model.dart';
import '../models/stock_movement_model.dart';

class PurchaseRepositoryImpl implements PurchaseRepository {
  final DatabaseHelper _dbHelper;
  final Uuid _uuid = const Uuid();

  PurchaseRepositoryImpl({DatabaseHelper? dbHelper})
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
  Future<List<Purchase>> getPurchases({
    DateTime? startDate,
    DateTime? endDate,
    String? supplierId,
    int limit = 50,
  }) async {
    final db = await _dbHelper.database;
    final businessId = await _getBusinessId();

    final whereClauses = <String>['p.business_id = ?'];
    final whereArgs = <dynamic>[businessId];

    if (supplierId != null && supplierId.isNotEmpty) {
      whereClauses.add('p.supplier_id = ?');
      whereArgs.add(supplierId);
    }
    if (startDate != null) {
      whereClauses.add('p.date >= ?');
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }
    if (endDate != null) {
      whereClauses.add('p.date <= ?');
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }

    final sql = '''
      SELECT p.*, s.name as supplier_name
      FROM purchases p
      LEFT JOIN suppliers s ON p.supplier_id = s.id
      WHERE ${whereClauses.join(' AND ')}
      ORDER BY p.date DESC, p.created_at DESC
      LIMIT ?
    ''';
    whereArgs.add(limit);

    final purchaseRows = await db.rawQuery(sql, whereArgs);
    final purchases = <Purchase>[];

    for (final row in purchaseRows) {
      final purchaseId = row['id'] as String;
      final itemRows = await db.query(
        'purchase_items',
        where: 'purchase_id = ?',
        whereArgs: [purchaseId],
      );
      final items = itemRows.map((m) => PurchaseItemModel.fromMap(m)).toList();
      purchases.add(PurchaseModel.fromMap(row, items: items));
    }

    return purchases;
  }

  @override
  Future<Purchase?> getPurchaseById(String id) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT p.*, s.name as supplier_name
      FROM purchases p
      LEFT JOIN suppliers s ON p.supplier_id = s.id
      WHERE p.id = ?
    ''', [id]);

    if (rows.isEmpty) return null;

    final itemRows = await db.query(
      'purchase_items',
      where: 'purchase_id = ?',
      whereArgs: [id],
    );
    final items = itemRows.map((m) => PurchaseItemModel.fromMap(m)).toList();
    return PurchaseModel.fromMap(rows.first, items: items);
  }

  @override
  Future<Purchase> createPurchase({
    String? supplierId,
    String? invoiceNumber,
    required List<PurchaseItem> items,
    String paymentStatus = 'PAID',
    DateTime? date,
    String? notes,
  }) async {
    if (items.isEmpty) {
      throw const ValidationFailure('Cannot record purchase with zero items.');
    }

    final db = await _dbHelper.database;
    final businessId = await _getBusinessId();
    final purchaseId = _uuid.v4();
    final now = DateTime.now();
    final effectiveDate = date ?? now;

    int totalPaise = 0;
    for (final item in items) {
      totalPaise += item.subtotalPaise;
    }

    await db.transaction((txn) async {
      // 1. Insert Purchase
      final purchaseModel = PurchaseModel(
        id: purchaseId,
        businessId: businessId,
        supplierId: supplierId,
        invoiceNumber: invoiceNumber?.trim(),
        items: items,
        totalPaise: totalPaise,
        paymentStatus: paymentStatus,
        date: effectiveDate,
        notes: notes?.trim(),
        createdAt: now,
        syncStatus: 'PENDING',
      );
      await txn.insert('purchases', purchaseModel.toMap());

      // 2. Insert items and increment product stock + record auditable movements
      for (final item in items) {
        final itemModel = PurchaseItemModel(
          id: _uuid.v4(),
          purchaseId: purchaseId,
          productId: item.productId,
          productName: item.productName,
          quantity: item.quantity,
          unitPricePaise: item.unitPricePaise,
          subtotalPaise: item.subtotalPaise,
        );
        await txn.insert('purchase_items', itemModel.toMap());

        // Update product inventory
        final pQuery = await txn.query(
          'products',
          where: 'id = ?',
          whereArgs: [item.productId],
        );
        if (pQuery.isNotEmpty) {
          final prod = ProductModel.fromMap(pQuery.first);
          final updatedStock = prod.stockQuantity + item.quantity;

          // Record movement
          final movement = StockMovementModel(
            id: _uuid.v4(),
            businessId: businessId,
            productId: item.productId,
            type: AppConstants.movementPurchase,
            quantity: item.quantity,
            previousStock: prod.stockQuantity,
            newStock: updatedStock,
            referenceId: purchaseId,
            note: invoiceNumber != null && invoiceNumber.isNotEmpty
                ? 'Purchase Inward (Bill #$invoiceNumber)'
                : 'Purchase Inward #${purchaseId.substring(0, 8)}',
            createdAt: now,
            syncStatus: 'PENDING',
          );
          await txn.insert('stock_movements', movement.toMap());

          // Update stock and update purchase price if positive
          final updateMap = <String, dynamic>{
            'stock_quantity': updatedStock,
            'updated_at': now.millisecondsSinceEpoch,
          };
          if (item.unitPricePaise > 0) {
            updateMap['purchase_price_paise'] = item.unitPricePaise;
          }

          await txn.update(
            'products',
            updateMap,
            where: 'id = ?',
            whereArgs: [item.productId],
          );
        }
      }
    });

    final created = await getPurchaseById(purchaseId);
    return created!;
  }

  @override
  Future<int> getTotalPurchasesPaise({DateTime? startDate, DateTime? endDate}) async {
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
      SELECT SUM(total_paise) as total
      FROM purchases
      WHERE ${whereClauses.join(' AND ')}
    ''', whereArgs);

    if (result.isNotEmpty && result.first['total'] != null) {
      return result.first['total'] as int;
    }
    return 0;
  }

  @override
  Future<int> getPurchasesCount({DateTime? startDate, DateTime? endDate}) async {
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
      SELECT COUNT(*) as count
      FROM purchases
      WHERE ${whereClauses.join(' AND ')}
    ''', whereArgs);

    if (result.isNotEmpty && result.first['count'] != null) {
      return result.first['count'] as int;
    }
    return 0;
  }
}

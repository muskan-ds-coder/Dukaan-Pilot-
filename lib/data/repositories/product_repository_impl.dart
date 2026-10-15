import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/stock_movement.dart';
import '../../domain/repositories/product_repository.dart';
import '../local/database_helper.dart';
import '../models/product_model.dart';
import '../models/stock_movement_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final DatabaseHelper _dbHelper;
  final Uuid _uuid = const Uuid();

  ProductRepositoryImpl({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<String> _getBusinessId() async {
    final prefs = await SharedPreferences.getInstance();
    final businessId = prefs.getString(AppConstants.keyCurrentBusinessId);
    if (businessId == null) {
      throw const DatabaseFailure('No active business found. Please complete business setup.');
    }
    return businessId;
  }

  @override
  Future<List<Product>> getProducts({
    String? query,
    String? category,
    bool? onlyLowStock,
    ProductSortOption sort = ProductSortOption.nameAsc,
  }) async {
    final db = await _dbHelper.database;
    final businessId = await _getBusinessId();

    final whereClauses = <String>['business_id = ?', 'is_active = 1'];
    final whereArgs = <dynamic>[businessId];

    if (query != null && query.trim().isNotEmpty) {
      whereClauses.add('(name LIKE ? OR brand LIKE ? OR barcode LIKE ? OR sku LIKE ?)');
      final term = '%${query.trim()}%';
      whereArgs.addAll([term, term, term, term]);
    }

    if (category != null && category.trim().isNotEmpty && category != 'All') {
      whereClauses.add('category = ?');
      whereArgs.add(category.trim());
    }

    if (onlyLowStock == true) {
      whereClauses.add('stock_quantity <= minimum_stock');
    }

    String orderBy;
    switch (sort) {
      case ProductSortOption.nameDesc:
        orderBy = 'name DESC';
        break;
      case ProductSortOption.stockAsc:
        orderBy = 'stock_quantity ASC, name ASC';
        break;
      case ProductSortOption.stockDesc:
        orderBy = 'stock_quantity DESC, name ASC';
        break;
      case ProductSortOption.priceAsc:
        orderBy = 'selling_price_paise ASC, name ASC';
        break;
      case ProductSortOption.priceDesc:
        orderBy = 'selling_price_paise DESC, name ASC';
        break;
      case ProductSortOption.recentlyUpdated:
        orderBy = 'updated_at DESC';
        break;
      case ProductSortOption.nameAsc:
        orderBy = 'name ASC';
        break;
    }

    final results = await db.query(
      'products',
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: orderBy,
    );

    return results.map((m) => ProductModel.fromMap(m)).toList();
  }

  @override
  Future<Product?> getProductById(String id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return ProductModel.fromMap(results.first);
  }

  @override
  Future<Product> addProduct(Product product) async {
    final db = await _dbHelper.database;
    final businessId = await _getBusinessId();
    final now = DateTime.now();
    final productId = product.id.isEmpty ? _uuid.v4() : product.id;

    final model = ProductModel(
      id: productId,
      businessId: businessId,
      name: product.name.trim(),
      category: product.category?.trim().isNotEmpty == true ? product.category!.trim() : 'General',
      brand: product.brand?.trim(),
      sku: product.sku?.trim().isNotEmpty == true
          ? product.sku!.trim()
          : 'SKU-${product.name.trim().substring(0, product.name.trim().length >= 3 ? 3 : product.name.trim().length).toUpperCase()}',
      barcode: product.barcode?.trim(),
      purchasePricePaise: product.purchasePricePaise,
      sellingPricePaise: product.sellingPricePaise,
      stockQuantity: product.stockQuantity,
      minimumStock: product.minimumStock,
      unit: product.unit,
      supplierId: product.supplierId,
      createdAt: now,
      updatedAt: now,
      isActive: true,
      syncStatus: 'PENDING',
    );

    await db.transaction((txn) async {
      await txn.insert('products', model.toMap());

      // If initial stock is positive, record opening movement
      if (model.stockQuantity > 0) {
        final movement = StockMovementModel(
          id: _uuid.v4(),
          businessId: businessId,
          productId: productId,
          type: AppConstants.movementAdjustmentIn,
          quantity: model.stockQuantity,
          previousStock: 0,
          newStock: model.stockQuantity,
          referenceId: 'OPENING_STOCK',
          note: 'Initial inventory opening balance',
          createdAt: now,
          syncStatus: 'PENDING',
        );
        await txn.insert('stock_movements', movement.toMap());
      }
    });

    return model;
  }

  @override
  Future<Product> updateProduct(Product product) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final model = ProductModel.fromEntity(product.copyWith(updatedAt: now));

    await db.update(
      'products',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );

    return model;
  }

  @override
  Future<void> archiveProduct(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'products',
      {
        'is_active': 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> recordStockMovement(StockMovement movement) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();

    await db.transaction((txn) async {
      // 1. Fetch current product
      final productQuery = await txn.query(
        'products',
        where: 'id = ?',
        whereArgs: [movement.productId],
      );

      if (productQuery.isEmpty) {
        throw const DatabaseFailure('Product does not exist.');
      }

      final product = ProductModel.fromMap(productQuery.first);
      int calculatedNewStock;

      switch (movement.type) {
        case AppConstants.movementPurchase:
        case AppConstants.movementAdjustmentIn:
        case AppConstants.movementReturnIn:
          calculatedNewStock = product.stockQuantity + movement.quantity;
          break;
        case AppConstants.movementSale:
        case AppConstants.movementAdjustmentOut:
        case AppConstants.movementReturnOut:
        case AppConstants.movementDamage:
          calculatedNewStock = product.stockQuantity - movement.quantity;
          if (calculatedNewStock < 0) {
            throw ValidationFailure(
              'Insufficient stock for this operation: requested ${movement.quantity}, available ${product.stockQuantity}',
            );
          }
          break;
        case AppConstants.movementCorrection:
          calculatedNewStock = movement.quantity;
          if (calculatedNewStock < 0) {
            throw const ValidationFailure('Stock count cannot be negative.');
          }
          break;
        default:
          calculatedNewStock = movement.newStock;
      }

      // 2. Insert movement
      final movementModel = StockMovementModel(
        id: movement.id.isEmpty ? _uuid.v4() : movement.id,
        businessId: product.businessId,
        productId: movement.productId,
        type: movement.type,
        quantity: movement.quantity,
        previousStock: product.stockQuantity,
        newStock: calculatedNewStock,
        referenceId: movement.referenceId,
        note: movement.note,
        createdAt: now,
        createdBy: movement.createdBy,
        syncStatus: 'PENDING',
      );

      await txn.insert('stock_movements', movementModel.toMap());

      // 3. Update product stock
      await txn.update(
        'products',
        {
          'stock_quantity': calculatedNewStock,
          'updated_at': now.millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [movement.productId],
      );
    });
  }

  @override
  Future<List<StockMovement>> getStockMovements({
    String? productId,
    String? movementType,
    int limit = 50,
  }) async {
    final db = await _dbHelper.database;
    final businessId = await _getBusinessId();

    final whereClauses = <String>['sm.business_id = ?'];
    final whereArgs = <dynamic>[businessId];

    if (productId != null) {
      whereClauses.add('sm.product_id = ?');
      whereArgs.add(productId);
    }

    if (movementType != null && movementType != 'ALL') {
      whereClauses.add('sm.type = ?');
      whereArgs.add(movementType);
    }

    final sql = '''
      SELECT sm.*, p.name as product_name
      FROM stock_movements sm
      JOIN products p ON sm.product_id = p.id
      WHERE ${whereClauses.join(' AND ')}
      ORDER BY sm.created_at DESC
      LIMIT ?
    ''';
    whereArgs.add(limit);

    final results = await db.rawQuery(sql, whereArgs);
    return results.map((m) => StockMovementModel.fromMap(m)).toList();
  }

  @override
  Future<List<Product>> getLowStockProducts() async {
    return getProducts(onlyLowStock: true, sort: ProductSortOption.stockAsc);
  }

  @override
  Future<List<String>> getCategories() async {
    final db = await _dbHelper.database;
    final businessId = await _getBusinessId();

    final results = await db.rawQuery(
      'SELECT DISTINCT category FROM products WHERE business_id = ? AND is_active = 1 AND category IS NOT NULL ORDER BY category ASC',
      [businessId],
    );

    return results
        .map((row) => row['category'] as String?)
        .where((c) => c != null && c.trim().isNotEmpty)
        .cast<String>()
        .toList();
  }

  @override
  Future<int> getTotalInventoryValuationPaise() async {
    final db = await _dbHelper.database;
    final businessId = await _getBusinessId();

    final result = await db.rawQuery(
      'SELECT SUM(stock_quantity * purchase_price_paise) as total FROM products WHERE business_id = ? AND is_active = 1 AND stock_quantity > 0',
      [businessId],
    );

    if (result.isNotEmpty && result.first['total'] != null) {
      return result.first['total'] as int;
    }
    return 0;
  }

  @override
  Future<int> getTotalInventoryUnits() async {
    final db = await _dbHelper.database;
    final businessId = await _getBusinessId();

    final result = await db.rawQuery(
      'SELECT SUM(stock_quantity) as total FROM products WHERE business_id = ? AND is_active = 1 AND stock_quantity > 0',
      [businessId],
    );

    if (result.isNotEmpty && result.first['total'] != null) {
      return result.first['total'] as int;
    }
    return 0;
  }

  @override
  Future<Map<String, int>> getStockMovementSummary() async {
    final db = await _dbHelper.database;
    final businessId = await _getBusinessId();

    final inwardResult = await db.rawQuery('''
      SELECT SUM(quantity) as total FROM stock_movements
      WHERE business_id = ? AND type IN ('PURCHASE', 'ADJUSTMENT_IN', 'RETURN_IN')
    ''', [businessId]);

    final outwardResult = await db.rawQuery('''
      SELECT SUM(quantity) as total FROM stock_movements
      WHERE business_id = ? AND type IN ('SALE', 'ADJUSTMENT_OUT', 'RETURN_OUT')
    ''', [businessId]);

    final damageResult = await db.rawQuery('''
      SELECT SUM(quantity) as total FROM stock_movements
      WHERE business_id = ? AND type = 'DAMAGE'
    ''', [businessId]);

    return {
      'totalIn': (inwardResult.isNotEmpty && inwardResult.first['total'] != null)
          ? inwardResult.first['total'] as int
          : 0,
      'totalOut': (outwardResult.isNotEmpty && outwardResult.first['total'] != null)
          ? outwardResult.first['total'] as int
          : 0,
      'totalDamaged': (damageResult.isNotEmpty && damageResult.first['total'] != null)
          ? damageResult.first['total'] as int
          : 0,
    };
  }
}

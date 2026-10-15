import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/repositories/supplier_repository.dart';
import '../local/database_helper.dart';
import '../models/supplier_model.dart';

class SupplierRepositoryImpl implements SupplierRepository {
  final DatabaseHelper _dbHelper;
  final Uuid _uuid = const Uuid();

  SupplierRepositoryImpl({DatabaseHelper? dbHelper})
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
  Future<List<Supplier>> getSuppliers({String? query}) async {
    final db = await _dbHelper.database;
    final businessId = await _getBusinessId();

    final whereClauses = <String>['business_id = ?', 'is_active = 1'];
    final whereArgs = <dynamic>[businessId];

    if (query != null && query.trim().isNotEmpty) {
      whereClauses.add('(name LIKE ? OR phone LIKE ?)');
      final term = '%${query.trim()}%';
      whereArgs.addAll([term, term]);
    }

    final results = await db.query(
      'suppliers',
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );

    return results.map((m) => SupplierModel.fromMap(m)).toList();
  }

  @override
  Future<Supplier?> getSupplierById(String id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'suppliers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return SupplierModel.fromMap(results.first);
  }

  @override
  Future<Supplier> addSupplier(Supplier supplier) async {
    final db = await _dbHelper.database;
    final businessId = await _getBusinessId();
    final id = supplier.id.isEmpty ? _uuid.v4() : supplier.id;
    final now = DateTime.now();

    final model = SupplierModel(
      id: id,
      businessId: businessId,
      name: supplier.name.trim(),
      phone: supplier.phone?.trim(),
      email: supplier.email?.trim(),
      address: supplier.address?.trim(),
      notes: supplier.notes?.trim(),
      createdAt: now,
      updatedAt: now,
      isActive: true,
      syncStatus: 'PENDING',
    );

    await db.insert('suppliers', model.toMap());
    return model;
  }

  @override
  Future<Supplier> updateSupplier(Supplier supplier) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final model = SupplierModel.fromEntity(supplier.copyWith(updatedAt: now));

    await db.update(
      'suppliers',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [supplier.id],
    );

    return model;
  }

  @override
  Future<void> deleteSupplier(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'suppliers',
      {
        'is_active': 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

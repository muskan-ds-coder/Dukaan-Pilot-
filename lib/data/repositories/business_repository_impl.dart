import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/business.dart';
import '../../domain/repositories/business_repository.dart';
import '../local/database_helper.dart';
import '../models/business_model.dart';

class BusinessRepositoryImpl implements BusinessRepository {
  final DatabaseHelper _dbHelper;
  final Uuid _uuid = const Uuid();

  BusinessRepositoryImpl({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<Business?> getCurrentBusiness() async {
    final prefs = await SharedPreferences.getInstance();
    final businessId = prefs.getString(AppConstants.keyCurrentBusinessId);
    if (businessId == null) return null;

    final db = await _dbHelper.database;
    final results = await db.query(
      'businesses',
      where: 'id = ?',
      whereArgs: [businessId],
    );

    if (results.isEmpty) return null;
    return BusinessModel.fromMap(results.first);
  }

  @override
  Future<Business> setupBusiness({
    required String name,
    required String ownerName,
    required String category,
    String? phone,
    String currency = 'INR',
  }) async {
    if (name.trim().isEmpty) {
      throw const ValidationFailure('Business name cannot be empty.');
    }
    if (ownerName.trim().isEmpty) {
      throw const ValidationFailure('Owner name cannot be empty.');
    }

    final prefs = await SharedPreferences.getInstance();
    final currentBusinessId = prefs.getString(AppConstants.keyCurrentBusinessId);
    final businessId = currentBusinessId ?? _uuid.v4();
    final now = DateTime.now();

    final model = BusinessModel(
      id: businessId,
      name: name.trim(),
      ownerName: ownerName.trim(),
      category: category.trim(),
      phone: phone?.trim(),
      currency: currency,
      createdAt: now,
      updatedAt: now,
      syncStatus: 'PENDING',
    );

    final db = await _dbHelper.database;
    await db.insert(
      'businesses',
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await prefs.setString(AppConstants.keyCurrentBusinessId, businessId);

    // Update current user if exists
    final userId = prefs.getString(AppConstants.keyCurrentUserId);
    if (userId != null) {
      await db.update(
        'users',
        {'business_id': businessId, 'display_name': ownerName.trim()},
        where: 'id = ?',
        whereArgs: [userId],
      );
    }

    return model;
  }

  @override
  Future<void> updateBusiness(Business business) async {
    final db = await _dbHelper.database;
    final model = BusinessModel.fromEntity(business);
    await db.update(
      'businesses',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [business.id],
    );
  }
}

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../local/database_helper.dart';
import '../local/demo_data_seeder.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final DatabaseHelper _dbHelper;
  final Uuid _uuid = const Uuid();

  AuthRepositoryImpl({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<AppUser?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(AppConstants.keyCurrentUserId);
    if (userId == null) return null;

    final db = await _dbHelper.database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  }

  @override
  Future<AppUser> signInWithEmailPassword(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || password.length < 6) {
      throw const AuthFailure('Please provide a valid email and minimum 6 character password.');
    }

    final db = await _dbHelper.database;
    final results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [cleanEmail],
    );

    if (results.isEmpty) {
      throw const AuthFailure('No account found for this email. Please register first.');
    }

    final user = UserModel.fromMap(results.first);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyCurrentUserId, user.id);
    await prefs.setString(AppConstants.keyCurrentBusinessId, user.businessId);
    return user;
  }

  @override
  Future<AppUser> registerWithEmailPassword(
    String email,
    String password,
    String displayName,
  ) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw const AuthFailure('Please enter a valid email address.');
    }
    if (password.length < 6) {
      throw const AuthFailure('Password must be at least 6 characters long.');
    }

    final db = await _dbHelper.database;
    final existing = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [cleanEmail],
    );

    if (existing.isNotEmpty) {
      throw const AuthFailure('An account with this email already exists.');
    }

    final userId = _uuid.v4();
    final businessId = _uuid.v4(); // Temporary until business setup completes
    final now = DateTime.now();

    final userModel = UserModel(
      id: userId,
      businessId: businessId,
      email: cleanEmail,
      displayName: displayName.trim().isEmpty ? 'Shop Owner' : displayName.trim(),
      role: 'OWNER',
      createdAt: now,
    );

    // Create placeholder business
    await db.insert('businesses', {
      'id': businessId,
      'name': 'My Shop',
      'owner_name': userModel.displayName ?? 'Shop Owner',
      'category': 'General Store',
      'currency': 'INR',
      'created_at': now.millisecondsSinceEpoch,
      'updated_at': now.millisecondsSinceEpoch,
      'sync_status': 'PENDING',
    });

    await db.insert('users', userModel.toMap());

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyCurrentUserId, userId);
    await prefs.setString(AppConstants.keyCurrentBusinessId, businessId);

    return userModel;
  }

  @override
  Future<AppUser> signInWithDemo() async {
    // Seed demo store data
    await DemoDataSeeder.seedDemoData();

    final db = await _dbHelper.database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [DemoDataSeeder.demoUserId],
    );

    final user = UserModel.fromMap(results.first);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyCurrentUserId, user.id);
    await prefs.setString(AppConstants.keyCurrentBusinessId, user.businessId);
    await prefs.setBool(AppConstants.keyIsFirstLaunch, false);
    return user;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (email.trim().isEmpty) {
      throw const AuthFailure('Please provide an email to reset your password.');
    }
    // Simulation / Firebase ready
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyCurrentUserId);
    await prefs.remove(AppConstants.keyCurrentBusinessId);
  }

  @override
  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyIsFirstLaunch) == false;
  }

  @override
  Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsFirstLaunch, false);
  }
}

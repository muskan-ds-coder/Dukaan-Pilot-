import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/ledger_entry.dart';
import '../../domain/repositories/customer_repository.dart';
import '../local/database_helper.dart';
import '../models/customer_model.dart';
import '../models/ledger_entry_model.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final DatabaseHelper _dbHelper;
  final Uuid _uuid = const Uuid();

  CustomerRepositoryImpl({DatabaseHelper? dbHelper})
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
  Future<List<Customer>> getCustomers({String? query}) async {
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
      'customers',
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'current_balance_paise DESC, name ASC',
    );

    return results.map((m) => CustomerModel.fromMap(m)).toList();
  }

  @override
  Future<Customer?> getCustomerById(String id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return CustomerModel.fromMap(results.first);
  }

  @override
  Future<Customer> addCustomer(Customer customer) async {
    final db = await _dbHelper.database;
    final businessId = await _getBusinessId();
    final customerId = customer.id.isEmpty ? _uuid.v4() : customer.id;
    final now = DateTime.now();

    final model = CustomerModel(
      id: customerId,
      businessId: businessId,
      name: customer.name.trim(),
      phone: customer.phone?.trim(),
      email: customer.email?.trim(),
      address: customer.address?.trim(),
      openingBalancePaise: customer.openingBalancePaise,
      currentBalancePaise: customer.openingBalancePaise,
      createdAt: now,
      updatedAt: now,
      isActive: true,
      syncStatus: 'PENDING',
    );

    await db.transaction((txn) async {
      await txn.insert('customers', model.toMap());

      if (model.openingBalancePaise > 0) {
        final ledger = LedgerEntryModel(
          id: _uuid.v4(),
          businessId: businessId,
          customerId: customerId,
          type: AppConstants.ledgerCredit,
          amountPaise: model.openingBalancePaise,
          referenceId: 'OPENING_BALANCE',
          description: 'Opening credit balance',
          createdAt: now,
          syncStatus: 'PENDING',
        );
        await txn.insert('customer_ledger', ledger.toMap());
      }
    });

    return model;
  }

  @override
  Future<Customer> updateCustomer(Customer customer) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final model = CustomerModel.fromEntity(customer.copyWith(updatedAt: now));

    await db.update(
      'customers',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );

    return model;
  }

  @override
  Future<void> recordPayment({
    required String customerId,
    required int amountPaise,
    String? note,
  }) async {
    if (amountPaise <= 0) {
      throw const ValidationFailure('Payment amount must be greater than zero.');
    }

    final db = await _dbHelper.database;
    final now = DateTime.now();

    await db.transaction((txn) async {
      final customerQuery = await txn.query(
        'customers',
        where: 'id = ?',
        whereArgs: [customerId],
      );

      if (customerQuery.isEmpty) {
        throw const DatabaseFailure('Customer not found.');
      }

      final customer = CustomerModel.fromMap(customerQuery.first);
      final newBalance = customer.currentBalancePaise - amountPaise;

      // 1. Insert Ledger payment entry
      final ledger = LedgerEntryModel(
        id: _uuid.v4(),
        businessId: customer.businessId,
        customerId: customerId,
        type: AppConstants.ledgerPayment,
        amountPaise: amountPaise,
        referenceId: 'PAYMENT_RECEIVED',
        description: note?.trim().isNotEmpty == true ? note!.trim() : 'Payment received',
        createdAt: now,
        syncStatus: 'PENDING',
      );
      await txn.insert('customer_ledger', ledger.toMap());

      // 2. Update customer balance
      await txn.update(
        'customers',
        {
          'current_balance_paise': newBalance,
          'updated_at': now.millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [customerId],
      );
    });
  }

  @override
  Future<List<LedgerEntry>> getCustomerLedger(String customerId) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'customer_ledger',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at DESC',
    );
    return results.map((m) => LedgerEntryModel.fromMap(m)).toList();
  }

  @override
  Future<int> getTotalOutstandingUdhaar() async {
    final db = await _dbHelper.database;
    final businessId = await _getBusinessId();

    final result = await db.rawQuery(
      'SELECT SUM(current_balance_paise) as total FROM customers WHERE business_id = ? AND is_active = 1 AND current_balance_paise > 0',
      [businessId],
    );

    if (result.isNotEmpty && result.first['total'] != null) {
      return result.first['total'] as int;
    }
    return 0;
  }
}

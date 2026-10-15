import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// SQLite Database Manager for DukaanPilot AI
/// Offline-first single source of truth for all business, inventory, and financial records.
class DatabaseHelper {
  static const String _databaseName = 'dukaanpilot.db';
  static const int _databaseVersion = 1;

  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._internal();

  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Initialize FFI for desktop platforms if running on Windows/Linux/macOS
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path;
    if (kIsWeb) {
      path = _databaseName;
    } else {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      path = join(documentsDirectory.path, _databaseName);
    }

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // 1. Businesses Table
    batch.execute('''
      CREATE TABLE businesses (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        owner_name TEXT NOT NULL,
        category TEXT NOT NULL,
        phone TEXT,
        currency TEXT NOT NULL DEFAULT 'INR',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'PENDING'
      )
    ''');

    // 2. Users Table
    batch.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        business_id TEXT NOT NULL,
        email TEXT NOT NULL,
        display_name TEXT,
        role TEXT NOT NULL DEFAULT 'OWNER',
        created_at INTEGER NOT NULL,
        FOREIGN KEY (business_id) REFERENCES businesses (id) ON DELETE CASCADE
      )
    ''');

    // 3. Suppliers Table
    batch.execute('''
      CREATE TABLE suppliers (
        id TEXT PRIMARY KEY,
        business_id TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        notes TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        sync_status TEXT NOT NULL DEFAULT 'PENDING'
      )
    ''');

    // 4. Products Table
    batch.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        business_id TEXT NOT NULL,
        name TEXT NOT NULL,
        category TEXT,
        brand TEXT,
        sku TEXT,
        barcode TEXT,
        purchase_price_paise INTEGER NOT NULL DEFAULT 0,
        selling_price_paise INTEGER NOT NULL DEFAULT 0,
        stock_quantity INTEGER NOT NULL DEFAULT 0,
        minimum_stock INTEGER NOT NULL DEFAULT 5,
        unit TEXT NOT NULL DEFAULT 'Piece',
        supplier_id TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        sync_status TEXT NOT NULL DEFAULT 'PENDING',
        FOREIGN KEY (supplier_id) REFERENCES suppliers (id) ON DELETE SET NULL
      )
    ''');

    // 5. Stock Movements Table
    batch.execute('''
      CREATE TABLE stock_movements (
        id TEXT PRIMARY KEY,
        business_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        previous_stock INTEGER NOT NULL,
        new_stock INTEGER NOT NULL,
        reference_id TEXT,
        note TEXT,
        created_at INTEGER NOT NULL,
        created_by TEXT,
        sync_status TEXT NOT NULL DEFAULT 'PENDING',
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');

    // 6. Customers Table
    batch.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        business_id TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        opening_balance_paise INTEGER NOT NULL DEFAULT 0,
        current_balance_paise INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        sync_status TEXT NOT NULL DEFAULT 'PENDING'
      )
    ''');

    // 7. Customer Ledger Table (Udhaar / Credit & Payments)
    batch.execute('''
      CREATE TABLE customer_ledger (
        id TEXT PRIMARY KEY,
        business_id TEXT NOT NULL,
        customer_id TEXT NOT NULL,
        type TEXT NOT NULL,
        amount_paise INTEGER NOT NULL,
        reference_id TEXT,
        description TEXT,
        created_at INTEGER NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'PENDING',
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');

    // 8. Sales Table
    batch.execute('''
      CREATE TABLE sales (
        id TEXT PRIMARY KEY,
        business_id TEXT NOT NULL,
        customer_id TEXT,
        subtotal_paise INTEGER NOT NULL,
        discount_paise INTEGER NOT NULL DEFAULT 0,
        total_paise INTEGER NOT NULL,
        payment_method TEXT NOT NULL DEFAULT 'Cash',
        notes TEXT,
        created_at INTEGER NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'PENDING',
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE SET NULL
      )
    ''');

    // 9. Sale Items Table
    batch.execute('''
      CREATE TABLE sale_items (
        id TEXT PRIMARY KEY,
        sale_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price_paise INTEGER NOT NULL,
        subtotal_paise INTEGER NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE
      )
    ''');

    // 10. Purchases Table
    batch.execute('''
      CREATE TABLE purchases (
        id TEXT PRIMARY KEY,
        business_id TEXT NOT NULL,
        supplier_id TEXT,
        invoice_number TEXT,
        total_paise INTEGER NOT NULL,
        payment_status TEXT NOT NULL DEFAULT 'PAID',
        date INTEGER NOT NULL,
        notes TEXT,
        created_at INTEGER NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'PENDING',
        FOREIGN KEY (supplier_id) REFERENCES suppliers (id) ON DELETE SET NULL
      )
    ''');

    // 11. Purchase Items Table
    batch.execute('''
      CREATE TABLE purchase_items (
        id TEXT PRIMARY KEY,
        purchase_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price_paise INTEGER NOT NULL,
        subtotal_paise INTEGER NOT NULL,
        FOREIGN KEY (purchase_id) REFERENCES purchases (id) ON DELETE CASCADE
      )
    ''');

    // 12. Expenses Table
    batch.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        business_id TEXT NOT NULL,
        category TEXT NOT NULL,
        amount_paise INTEGER NOT NULL,
        description TEXT,
        date INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'PENDING'
      )
    ''');

    // 13. Sync Queue Table
    batch.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        business_id TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_attempt INTEGER,
        status TEXT NOT NULL DEFAULT 'PENDING',
        created_at INTEGER NOT NULL
      )
    ''');

    // Performance Indices
    batch.execute('CREATE INDEX idx_products_business ON products (business_id)');
    batch.execute('CREATE INDEX idx_products_name ON products (name)');
    batch.execute('CREATE INDEX idx_movements_product ON stock_movements (product_id)');
    batch.execute('CREATE INDEX idx_sales_business_date ON sales (business_id, created_at)');
    batch.execute('CREATE INDEX idx_ledger_customer ON customer_ledger (customer_id)');
    batch.execute('CREATE INDEX idx_expenses_business_date ON expenses (business_id, date)');
    batch.execute('CREATE INDEX idx_sync_queue_status ON sync_queue (status)');

    await batch.commit(noResult: true);
  }

  /// Clears database tables for testing or complete reset
  Future<void> clearDatabase() async {
    final db = await database;
    final tables = [
      'sync_queue',
      'expenses',
      'purchase_items',
      'purchases',
      'sale_items',
      'sales',
      'customer_ledger',
      'customers',
      'stock_movements',
      'products',
      'suppliers',
      'users',
      'businesses',
    ];
    for (final table in tables) {
      await db.delete(table);
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}

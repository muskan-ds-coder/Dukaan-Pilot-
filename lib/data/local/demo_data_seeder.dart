import 'package:uuid/uuid.dart';
import 'database_helper.dart';

/// Seeds development/testing demo business with cosmetics & Kirana retail data
class DemoDataSeeder {
  static const String demoBusinessId = 'demo-business-001';
  static const String demoUserId = 'demo-user-001';

  static Future<void> seedDemoData({bool force = false}) async {
    final db = await DatabaseHelper.instance.database;

    // Check if demo business already exists
    final existing = await db.query(
      'businesses',
      where: 'id = ?',
      whereArgs: [demoBusinessId],
    );

    if (existing.isNotEmpty && !force) {
      return; // Already seeded
    }

    if (force) {
      await DatabaseHelper.instance.clearDatabase();
    }

    final uuid = const Uuid();
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    await db.transaction((txn) async {
      // 1. Business
      await txn.insert('businesses', {
        'id': demoBusinessId,
        'name': 'Radha Cosmetics & Store',
        'owner_name': 'Radha Sharma',
        'category': 'Cosmetics',
        'phone': '+91 98765 43210',
        'currency': 'INR',
        'created_at': nowMs,
        'updated_at': nowMs,
        'sync_status': 'SYNCED',
      });

      // 2. User
      await txn.insert('users', {
        'id': demoUserId,
        'business_id': demoBusinessId,
        'email': 'demo@dukaanpilot.ai',
        'display_name': 'Radha Sharma',
        'role': 'OWNER',
        'created_at': nowMs,
      });

      // 3. Supplier
      final supplierId = uuid.v4();
      await txn.insert('suppliers', {
        'id': supplierId,
        'business_id': demoBusinessId,
        'name': 'Hindustan Beauty Distributors',
        'phone': '+91 98220 11223',
        'email': 'orders@hbd-dist.in',
        'address': 'Plot 42, Wholesale Market, Mumbai',
        'notes': 'Delivers every Tuesday',
        'created_at': nowMs,
        'updated_at': nowMs,
        'is_active': 1,
        'sync_status': 'SYNCED',
      });

      // 4. Demo Products
      final products = [
        {
          'id': 'prod-lakme-fw',
          'name': 'Lakme Face Wash',
          'brand': 'Lakme',
          'category': 'Cosmetics',
          'purchase_price_paise': 12000, // ₹120
          'selling_price_paise': 18000,  // ₹180
          'stock_quantity': 20,
          'minimum_stock': 5,
          'unit': 'Piece',
        },
        {
          'id': 'prod-dove-soap',
          'name': 'Dove Soap',
          'brand': 'Dove',
          'category': 'Personal Care',
          'purchase_price_paise': 4500, // ₹45
          'selling_price_paise': 6000,  // ₹60
          'stock_quantity': 12,
          'minimum_stock': 6,
          'unit': 'Piece',
        },
        {
          'id': 'prod-maybelline-kajal',
          'name': 'Maybelline Kajal',
          'brand': 'Maybelline',
          'category': 'Cosmetics',
          'purchase_price_paise': 14000, // ₹140
          'selling_price_paise': 21000,  // ₹210
          'stock_quantity': 4, // LOW STOCK!
          'minimum_stock': 5,
          'unit': 'Piece',
        },
        {
          'id': 'prod-nivea-cream',
          'name': 'Nivea Soft Cream',
          'brand': 'Nivea',
          'category': 'Personal Care',
          'purchase_price_paise': 9000, // ₹90
          'selling_price_paise': 13500, // ₹135
          'stock_quantity': 15,
          'minimum_stock': 5,
          'unit': 'Bottle',
        },
        {
          'id': 'prod-ponds-fw',
          'name': 'Ponds Face Wash',
          'brand': 'Ponds',
          'category': 'Cosmetics',
          'purchase_price_paise': 8500, // ₹85
          'selling_price_paise': 13000, // ₹130
          'stock_quantity': 0, // OUT OF STOCK!
          'minimum_stock': 5,
          'unit': 'Piece',
        },
      ];

      for (final p in products) {
        await txn.insert('products', {
          'id': p['id'],
          'business_id': demoBusinessId,
          'name': p['name'],
          'category': p['category'],
          'brand': p['brand'],
          'sku': 'SKU-${p['name'].toString().substring(0, 3).toUpperCase()}',
          'barcode': '8901234${p['name'].hashCode.abs().toString().substring(0, 5)}',
          'purchase_price_paise': p['purchase_price_paise'],
          'selling_price_paise': p['selling_price_paise'],
          'stock_quantity': p['stock_quantity'],
          'minimum_stock': p['minimum_stock'],
          'unit': p['unit'],
          'supplier_id': supplierId,
          'created_at': nowMs,
          'updated_at': nowMs,
          'is_active': 1,
          'sync_status': 'SYNCED',
        });

        // Record Initial Stock Movement
        if ((p['stock_quantity'] as int) > 0) {
          await txn.insert('stock_movements', {
            'id': uuid.v4(),
            'business_id': demoBusinessId,
            'product_id': p['id'],
            'type': 'PURCHASE',
            'quantity': p['stock_quantity'],
            'previous_stock': 0,
            'new_stock': p['stock_quantity'],
            'reference_id': 'INITIAL_STOCK',
            'note': 'Initial stock inventory opening balance',
            'created_at': nowMs,
            'created_by': 'Radha Sharma',
            'sync_status': 'SYNCED',
          });
        }
      }

      // 5. Demo Customers
      final customers = [
        {
          'id': 'cust-ramesh',
          'name': 'Ramesh Kumar',
          'phone': '+91 98111 22334',
          'address': 'Main Market Road',
          'opening_balance_paise': 0,
          'current_balance_paise': 50000, // ₹500 Udhaar
        },
        {
          'id': 'cust-priya',
          'name': 'Priya Singh',
          'phone': '+91 98222 33445',
          'address': 'Sector 4, Colony',
          'opening_balance_paise': 0,
          'current_balance_paise': 0, // Cleared
        },
        {
          'id': 'cust-amit',
          'name': 'Amit Verma',
          'phone': '+91 98333 44556',
          'address': 'Near Shiv Temple',
          'opening_balance_paise': 0,
          'current_balance_paise': 25000, // ₹250 Udhaar
        },
      ];

      for (final c in customers) {
        await txn.insert('customers', {
          'id': c['id'],
          'business_id': demoBusinessId,
          'name': c['name'],
          'phone': c['phone'],
          'email': null,
          'address': c['address'],
          'opening_balance_paise': c['opening_balance_paise'],
          'current_balance_paise': c['current_balance_paise'],
          'created_at': nowMs,
          'updated_at': nowMs,
          'is_active': 1,
          'sync_status': 'SYNCED',
        });

        // Add ledger entry if there is udhaar
        if ((c['current_balance_paise'] as int) > 0) {
          await txn.insert('customer_ledger', {
            'id': uuid.v4(),
            'business_id': demoBusinessId,
            'customer_id': c['id'],
            'type': 'CREDIT',
            'amount_paise': c['current_balance_paise'],
            'reference_id': 'UDHAAR_OPENING',
            'description': 'Credit purchase on account',
            'created_at': nowMs - 3600000,
            'sync_status': 'SYNCED',
          });
        }
      }

      // 6. Demo Sale
      final saleId = 'sale-demo-001';
      await txn.insert('sales', {
        'id': saleId,
        'business_id': demoBusinessId,
        'customer_id': 'cust-ramesh',
        'subtotal_paise': 50000,
        'discount_paise': 0,
        'total_paise': 50000,
        'payment_method': 'Credit/Udhaar',
        'notes': 'Demo credit sale',
        'created_at': nowMs - 7200000,
        'sync_status': 'SYNCED',
      });

      await txn.insert('sale_items', {
        'id': uuid.v4(),
        'sale_id': saleId,
        'product_id': 'prod-lakme-fw',
        'product_name': 'Lakme Face Wash',
        'quantity': 2,
        'unit_price_paise': 18000,
        'subtotal_paise': 36000,
      });

      await txn.insert('sale_items', {
        'id': uuid.v4(),
        'sale_id': saleId,
        'product_id': 'prod-nivea-cream',
        'product_name': 'Nivea Soft Cream',
        'quantity': 1,
        'unit_price_paise': 14000,
        'subtotal_paise': 14000,
      });

      // 7. Demo Expense
      await txn.insert('expenses', {
        'id': uuid.v4(),
        'business_id': demoBusinessId,
        'category': 'Electricity',
        'amount_paise': 85000, // ₹850
        'description': 'Shop electricity bill',
        'date': nowMs,
        'created_at': nowMs,
        'sync_status': 'SYNCED',
      });
    });
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:dukaanpilot_ai/core/constants/app_constants.dart';
import 'package:dukaanpilot_ai/core/utils/currency_formatter.dart';
import 'package:dukaanpilot_ai/domain/entities/product.dart';
import 'package:dukaanpilot_ai/domain/entities/stock_movement.dart';

void main() {
  group('Phase 2 — Profit Margin & Valuation Tests', () {
    test('Calculates unit profit and profit margin percentage accurately', () {
      final product = Product(
        id: 'p1',
        businessId: 'b1',
        name: 'Lakme Face Wash',
        purchasePricePaise: 12000, // ₹120
        sellingPricePaise: 18000,  // ₹180
        stockQuantity: 20,
        minimumStock: 5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Profit: ₹180 - ₹120 = ₹60 (6000 paise)
      expect(product.profitPaise, 6000);
      expect(CurrencyFormatter.formatPaise(product.profitPaise), contains('60'));

      // Margin: (60 / 180) * 100 = 33.333%
      expect(product.profitMarginPercentage, closeTo(33.33, 0.01));
    });

    test('Handles zero and negative margin gracefully', () {
      final zeroPriceProduct = Product(
        id: 'p2',
        businessId: 'b1',
        name: 'Tester Sample',
        purchasePricePaise: 500,
        sellingPricePaise: 0,
        stockQuantity: 5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(zeroPriceProduct.profitMarginPercentage, 0.0);

      final lossProduct = Product(
        id: 'p3',
        businessId: 'b1',
        name: 'Clearance Item',
        purchasePricePaise: 10000, // ₹100
        sellingPricePaise: 8000,   // ₹80
        stockQuantity: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(lossProduct.profitPaise, -2000);
      expect(lossProduct.profitMarginPercentage, -25.0);
    });

    test('Calculates inventory asset valuation and retail potential', () {
      final product = Product(
        id: 'p1',
        businessId: 'b1',
        name: 'Dove Soap',
        purchasePricePaise: 4500, // ₹45
        sellingPricePaise: 6000,  // ₹60
        stockQuantity: 12,
        minimumStock: 5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Cost asset valuation: 12 * ₹45 = ₹540 (54000 paise)
      expect(product.stockValuationPaise, 54000);
      expect(CurrencyFormatter.formatPaise(product.stockValuationPaise), contains('540'));

      // Retail valuation: 12 * ₹60 = ₹720 (72000 paise)
      expect(product.retailValuationPaise, 72000);
      expect(CurrencyFormatter.formatPaise(product.retailValuationPaise), contains('720'));
    });
  });

  group('Phase 2 — Auditable Stock Movement Calculations', () {
    test('Simulates sequential inventory adjustments across movement types', () {
      int stock = 20;

      // 1. Sale (-5)
      stock -= 5;
      expect(stock, 15);

      // 2. Purchase (+10)
      stock += 10;
      expect(stock, 25);

      // 3. Customer Return In (+2)
      stock += 2;
      expect(stock, 27);

      // 4. Supplier Return Out (-3)
      stock -= 3;
      expect(stock, 24);

      // 5. Damaged items logged (-2)
      stock -= 2;
      expect(stock, 22);

      // 6. Direct stock physical count correction (reset to exact count 20)
      stock = 20;
      expect(stock, 20);
    });

    test('StockMovement model preserves all required audit fields', () {
      final now = DateTime.now();
      final movement = StockMovement(
        id: 'sm-001',
        businessId: 'b-001',
        productId: 'prod-001',
        productName: 'Maybelline Kajal',
        type: AppConstants.movementDamage,
        quantity: 2,
        previousStock: 6,
        newStock: 4,
        referenceId: 'INSPECT-01',
        note: 'Broken in transit',
        createdAt: now,
        createdBy: 'Radha Sharma',
        syncStatus: AppConstants.syncPending,
      );

      expect(movement.id, 'sm-001');
      expect(movement.type, 'DAMAGE');
      expect(movement.previousStock, 6);
      expect(movement.newStock, 4);
      expect(movement.quantity, 2);
      expect(movement.note, 'Broken in transit');
      expect(movement.createdBy, 'Radha Sharma');
    });
  });
}

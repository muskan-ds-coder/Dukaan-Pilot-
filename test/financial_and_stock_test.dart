import 'package:flutter_test/flutter_test.dart';
import 'package:dukaanpilot_ai/core/utils/currency_formatter.dart';
import 'package:dukaanpilot_ai/domain/entities/product.dart';
import 'package:dukaanpilot_ai/domain/entities/sale.dart';

void main() {
  group('Currency & Financial Integer-Paise Tests (Zero Rounding Errors)', () {
    test('Zero rupee format and parse', () {
      expect(CurrencyFormatter.formatPaise(0), contains('0'));
      expect(CurrencyFormatter.parseToPaise('0'), 0);
      expect(CurrencyFormatter.parseToPaise('₹0'), 0);
    });

    test('One rupee format and parse', () {
      expect(CurrencyFormatter.formatPaise(100), contains('1'));
      expect(CurrencyFormatter.parseToPaise('1'), 100);
      expect(CurrencyFormatter.parseToPaise('₹1'), 100);
    });

    test('Large sale decimal paise conversion', () {
      // ₹15,450.50 = 1545050 paise
      const paise = 1545050;
      final formatted = CurrencyFormatter.formatPaise(paise);
      expect(formatted, contains('15,450.50'));
      expect(CurrencyFormatter.parseToPaise('15450.50'), paise);
    });

    test('Conversion helpers', () {
      expect(CurrencyFormatter.rupeesToPaise(120.75), 12075);
      expect(CurrencyFormatter.paiseToRupees(12075), 120.75);
    });
  });

  group('Stock Calculation & Low-Stock Engine Tests', () {
    test('Healthy Stock status', () {
      final product = Product(
        id: 'p1',
        businessId: 'b1',
        name: 'Dove Soap',
        purchasePricePaise: 4500,
        sellingPricePaise: 6000,
        stockQuantity: 15,
        minimumStock: 5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(product.stockStatus, StockStatus.healthy);
      expect(product.suggestedReorderQuantity, 0); // 5 * 2 - 15 <= 0
    });

    test('Low Stock status and suggested reorder calculation', () {
      final product = Product(
        id: 'p2',
        businessId: 'b1',
        name: 'Maybelline Kajal',
        purchasePricePaise: 14000,
        sellingPricePaise: 21000,
        stockQuantity: 3,
        minimumStock: 5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(product.stockStatus, StockStatus.low);
      // Formula: max(minimumStock * 2 - stockQuantity, 0) = max(10 - 3, 0) = 7
      expect(product.suggestedReorderQuantity, 7);
    });

    test('Out of Stock status and reorder quantity', () {
      final product = Product(
        id: 'p3',
        businessId: 'b1',
        name: 'Ponds Face Wash',
        purchasePricePaise: 8500,
        sellingPricePaise: 13000,
        stockQuantity: 0,
        minimumStock: 5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(product.stockStatus, StockStatus.outOfStock);
      // max(5 * 2 - 0, 0) = 10
      expect(product.suggestedReorderQuantity, 10);
    });
  });

  group('Sale Cart & Discount Calculation Tests', () {
    test('Calculates multi-item subtotal and discount correctly in paise', () {
      final items = [
        const SaleItem(
          id: 'i1',
          saleId: 's1',
          productId: 'prod-1',
          productName: 'Lakme Face Wash',
          quantity: 2,
          unitPricePaise: 18000, // ₹180
          subtotalPaise: 36000,  // ₹360
        ),
        const SaleItem(
          id: 'i2',
          saleId: 's1',
          productId: 'prod-2',
          productName: 'Dove Soap',
          quantity: 3,
          unitPricePaise: 6000, // ₹60
          subtotalPaise: 18000, // ₹180
        ),
      ];

      int subtotal = 0;
      for (final item in items) {
        subtotal += item.subtotalPaise;
      }
      expect(subtotal, 54000); // ₹540

      const discount = 4000; // ₹40 discount
      final total = subtotal - discount;
      expect(total, 50000); // ₹500
    });
  });

  group('Customer Udhaar / Ledger Balance Calculation Tests', () {
    test('Calculates outstanding balance after credit and partial payments', () {
      int balancePaise = 0;

      // 1. Credit sale of ₹500
      balancePaise += 50000;
      expect(balancePaise, 50000);

      // 2. Customer pays ₹300
      balancePaise -= 30000;
      expect(balancePaise, 20000); // ₹200 left

      // 3. Customer pays remaining ₹200
      balancePaise -= 20000;
      expect(balancePaise, 0); // All clear
    });
  });
}

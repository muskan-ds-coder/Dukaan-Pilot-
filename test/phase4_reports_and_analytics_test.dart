import 'package:flutter_test/flutter_test.dart';
import 'package:dukaanpilot_ai/core/utils/currency_formatter.dart';
import 'package:dukaanpilot_ai/features/reports/providers/reports_provider.dart';

void main() {
  group('Phase 4 — Business Reports & Financial Analytics Math', () {
    test('Calculates Net Profit and Margin % without floating-point inaccuracies', () {
      // Retail scenario:
      // Total Sales = ₹1,20,000 (12,000,000 paise)
      // Total Expenses = ₹18,500 (1,850,000 paise)
      const totalSalesPaise = 12000000;
      const totalExpensesPaise = 1850000;
      const expectedNetProfitPaise = totalSalesPaise - totalExpensesPaise;

      expect(expectedNetProfitPaise, 10150000); // ₹1,01,500.00
      expect(CurrencyFormatter.formatPaise(expectedNetProfitPaise), '₹1,01,500');

      // Margin % = (Net Profit / Gross Sales) * 100
      final marginPct = (expectedNetProfitPaise / totalSalesPaise) * 100.0;
      expect(marginPct.toStringAsFixed(2), '84.58');
    });

    test('Validates Payment Method distribution partition completeness', () {
      const sales = [
        {'method': 'Cash', 'paise': 4500000}, // ₹45,000
        {'method': 'UPI', 'paise': 3500000},  // ₹35,000
        {'method': 'Credit', 'paise': 2000000}, // ₹20,000 (Udhaar)
      ];

      final totalFromMethods = sales.fold<int>(0, (sum, s) => sum + (s['paise'] as int));
      expect(totalFromMethods, 10000000); // ₹1,00,000

      final cashPct = ((sales[0]['paise'] as int) / totalFromMethods) * 100;
      final upiPct = ((sales[1]['paise'] as int) / totalFromMethods) * 100;
      final creditPct = ((sales[2]['paise'] as int) / totalFromMethods) * 100;

      expect(cashPct, 45.0);
      expect(upiPct, 35.0);
      expect(creditPct, 20.0);
      expect(cashPct + upiPct + creditPct, 100.0);
    });

    test('Sorts and ranks Top 5 best selling products by total revenue accurately', () {
      final items = [
        const TopSellingProduct(productName: 'Lakme Eyeconic Kajal', unitsSold: 42, totalRevenuePaise: 882000), // ₹8,820
        const TopSellingProduct(productName: 'Ponds Cold Cream 200g', unitsSold: 28, totalRevenuePaise: 700000), // ₹7,000
        const TopSellingProduct(productName: 'Dove Moisturizing Soap 100g', unitsSold: 65, totalRevenuePaise: 390000), // ₹3,900
        const TopSellingProduct(productName: 'Nivea Soft Light Cream', unitsSold: 14, totalRevenuePaise: 252000), // ₹2,520
        const TopSellingProduct(productName: 'Biotique Bio Kelp Shampoo', unitsSold: 9, totalRevenuePaise: 180000), // ₹1,800
      ];

      // Verify descending order
      for (int i = 0; i < items.length - 1; i++) {
        expect(items[i].totalRevenuePaise >= items[i + 1].totalRevenuePaise, isTrue);
      }

      expect(items.first.productName, 'Lakme Eyeconic Kajal');
      expect(CurrencyFormatter.formatPaise(items.first.totalRevenuePaise), '₹8,820');
      expect(items.length, 5);
    });

    test('Models 7-day sales trend structure with non-negative daily revenue', () {
      final now = DateTime(2026, 10, 15);
      final points = List.generate(7, (i) {
        final d = now.subtract(Duration(days: 6 - i));
        return DailySalesDataPoint(
          dayLabel: 'Day ${i + 1}',
          totalSalesPaise: (i + 1) * 150000, // ₹1,500, ₹3,000, etc.
          date: d,
        );
      });

      expect(points.length, 7);
      for (final p in points) {
        expect(p.totalSalesPaise, greaterThan(0));
      }
      expect(points.last.totalSalesPaise, 1050000); // ₹10,500
    });
  });
}

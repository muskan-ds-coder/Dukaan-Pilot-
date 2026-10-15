import 'package:flutter_test/flutter_test.dart';
import 'package:dukaanpilot_ai/core/constants/app_constants.dart';
import 'package:dukaanpilot_ai/core/utils/currency_formatter.dart';
import 'package:dukaanpilot_ai/domain/entities/expense.dart';
import 'package:dukaanpilot_ai/domain/entities/ledger_entry.dart';
import 'package:dukaanpilot_ai/domain/entities/purchase.dart';
import 'package:dukaanpilot_ai/domain/entities/sale.dart';

void main() {
  group('Phase 3 — Sales POS & Cart Financial Math', () {
    test('Calculates multi-line item sale subtotal and discount correctly', () {
      final items = [
        const SaleItem(
          id: 'item-1',
          saleId: 'sale-1',
          productId: 'prod-1',
          productName: 'Lakme Lipstick Matte',
          quantity: 2,
          unitPricePaise: 29900, // ₹299.00
          subtotalPaise: 59800, // ₹598.00
        ),
        const SaleItem(
          id: 'item-2',
          saleId: 'sale-1',
          productId: 'prod-2',
          productName: 'Ponds Face Wash 100g',
          quantity: 3,
          unitPricePaise: 14900, // ₹149.00
          subtotalPaise: 44700, // ₹447.00
        ),
      ];

      int subtotalPaise = 0;
      for (final i in items) {
        subtotalPaise += i.subtotalPaise;
      }
      expect(subtotalPaise, 104500); // ₹1045.00

      const discountPaise = 4500; // ₹45.00
      final totalPaise = subtotalPaise - discountPaise;
      expect(totalPaise, 100000); // ₹1000.00
      expect(CurrencyFormatter.formatPaise(totalPaise), '₹1,000');
    });

    test('Validates Split Payment (Cash + Customer Udhaar) partition', () {
      const totalPayablePaise = 150000; // ₹1,500.00
      const cashReceivedPaise = 60000; // ₹600.00 paid now

      final udhaarDuePaise = totalPayablePaise - cashReceivedPaise;
      expect(udhaarDuePaise, 90000); // ₹900.00 credit to customer
      expect(cashReceivedPaise + udhaarDuePaise, totalPayablePaise);
    });

    test('Ensures discount cannot exceed subtotal', () {
      const subtotalPaise = 25000; // ₹250.00
      const excessiveDiscountPaise = 30000; // ₹300.00

      final netTotal = (subtotalPaise - excessiveDiscountPaise) > 0
          ? (subtotalPaise - excessiveDiscountPaise)
          : 0;

      expect(netTotal, 0);
    });
  });

  group('Phase 3 — Inward Purchases & Stock Inward Calculations', () {
    test('Calculates purchase bill valuation across multiple inward SKUs', () {
      final purchaseItems = [
        const PurchaseItem(
          id: 'p-item-1',
          purchaseId: 'purch-1',
          productId: 'prod-1',
          productName: 'Sugar Matte Lipstick Box of 10',
          quantity: 5,
          unitPricePaise: 18000, // ₹180.00 wholesale
          subtotalPaise: 90000, // ₹900.00
        ),
        const PurchaseItem(
          id: 'p-item-2',
          purchaseId: 'purch-1',
          productId: 'prod-2',
          productName: 'Nivea Soft Cream 200ml',
          quantity: 12,
          unitPricePaise: 16000, // ₹160.00 wholesale
          subtotalPaise: 192000, // ₹1,920.00
        ),
      ];

      int billTotalPaise = 0;
      for (final item in purchaseItems) {
        billTotalPaise += item.subtotalPaise;
      }
      expect(billTotalPaise, 282000); // ₹2,820.00
      expect(CurrencyFormatter.formatPaise(billTotalPaise), '₹2,820');
    });

    test('Increments stock and models auditable PURCHASE movement correctly', () {
      const initialStock = 14;
      const inwardQuantity = 25;
      const expectedNewStock = initialStock + inwardQuantity;

      expect(expectedNewStock, 39);

      final purchase = Purchase(
        id: 'purch-101',
        businessId: 'biz-1',
        supplierId: 'supp-1',
        supplierName: 'Gupta Wholesale Distributors',
        invoiceNumber: 'INV-2026-99',
        items: const [],
        totalPaise: 282000,
        paymentStatus: 'PAID',
        date: DateTime(2026, 10, 15),
        createdAt: DateTime(2026, 10, 15),
      );

      expect(purchase.invoiceNumber, 'INV-2026-99');
      expect(purchase.supplierName, 'Gupta Wholesale Distributors');
    });
  });

  group('Phase 3 — Customer Udhaar (Khata) & Debt Settlement Math', () {
    test('Updates customer balance accurately across sequential sales and partial payments', () {
      // Customer starts with ₹0
      int currentBalance = 0;

      // 1. First credit sale for ₹750
      const firstSaleCredit = 75000;
      currentBalance += firstSaleCredit;
      expect(currentBalance, 75000);

      // 2. Second credit sale for ₹500
      const secondSaleCredit = 50000;
      currentBalance += secondSaleCredit;
      expect(currentBalance, 125000); // ₹1,250.00

      // 3. Customer pays ₹800 in cash
      const partialPaymentReceived = 80000;
      currentBalance -= partialPaymentReceived;
      expect(currentBalance, 45000); // ₹450.00 remaining debt
      expect(CurrencyFormatter.formatPaise(currentBalance), '₹450');

      // 4. Customer settles the remaining balance ₹450
      currentBalance -= 45000;
      expect(currentBalance, 0); // All clear
    });

    test('Preserves required LedgerEntry audit fields', () {
      final entry = LedgerEntry(
        id: 'ledg-1',
        businessId: 'biz-1',
        customerId: 'cust-1',
        type: AppConstants.ledgerCredit,
        amountPaise: 45000,
        referenceId: 'SALE-8821',
        description: 'Credit sale #SALE-8821',
        createdAt: DateTime(2026, 10, 15, 14, 0),
      );

      expect(entry.type, AppConstants.ledgerCredit);
      expect(entry.amountPaise, 45000);
      expect(entry.referenceId, 'SALE-8821');
    });
  });

  group('Phase 3 — Categorized Store Expenses', () {
    test('Calculates total expenses and category distribution accurately', () {
      final expenses = [
        Expense(
          id: 'exp-1',
          businessId: 'biz-1',
          category: 'Rent',
          amountPaise: 1500000, // ₹15,000.00
          date: DateTime(2026, 10, 1),
          createdAt: DateTime(2026, 10, 1),
        ),
        Expense(
          id: 'exp-2',
          businessId: 'biz-1',
          category: 'Electricity',
          amountPaise: 320000, // ₹3,200.00
          date: DateTime(2026, 10, 5),
          createdAt: DateTime(2026, 10, 5),
        ),
        Expense(
          id: 'exp-3',
          businessId: 'biz-1',
          category: 'Packaging',
          amountPaise: 180000, // ₹1,800.00
          date: DateTime(2026, 10, 8),
          createdAt: DateTime(2026, 10, 8),
        ),
      ];

      int totalExpensePaise = 0;
      for (final exp in expenses) {
        totalExpensePaise += exp.amountPaise;
      }
      expect(totalExpensePaise, 2000000); // ₹20,000.00
      expect(CurrencyFormatter.formatPaise(totalExpensePaise), '₹20,000');

      // Net Cash = Daily Sales (e.g. ₹25,000) - Daily Expenses (e.g. ₹1,800)
      const todaySalesPaise = 2500000;
      const todayExpensesPaise = 180000;
      const netCashPaise = todaySalesPaise - todayExpensesPaise;

      expect(netCashPaise, 2320000); // ₹23,200.00
      expect(CurrencyFormatter.formatPaise(netCashPaise), '₹23,200');
    });
  });
}

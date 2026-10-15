import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/database_provider.dart';

enum ReportTimeRange {
  today,
  last7Days,
  last30Days,
  allTime,
}

final selectedReportTimeRangeProvider =
    StateProvider<ReportTimeRange>((ref) => ReportTimeRange.last7Days);

class DailySalesDataPoint {
  final String dayLabel;
  final int totalSalesPaise;
  final DateTime date;

  const DailySalesDataPoint({
    required this.dayLabel,
    required this.totalSalesPaise,
    required this.date,
  });
}

class TopSellingProduct {
  final String productName;
  final int unitsSold;
  final int totalRevenuePaise;

  const TopSellingProduct({
    required this.productName,
    required this.unitsSold,
    required this.totalRevenuePaise,
  });
}

class ReportsData {
  final int totalSalesPaise;
  final int totalPurchasesPaise;
  final int totalExpensesPaise;
  final int netProfitPaise;
  final int outstandingUdhaarPaise;
  final int totalTransactions;
  final Map<String, int> paymentMethodSplitPaise;
  final List<DailySalesDataPoint> last7DaysSales;
  final List<TopSellingProduct> topProducts;
  final Map<String, int> expenseCategoryBreakdownPaise;

  const ReportsData({
    required this.totalSalesPaise,
    required this.totalPurchasesPaise,
    required this.totalExpensesPaise,
    required this.netProfitPaise,
    required this.outstandingUdhaarPaise,
    required this.totalTransactions,
    required this.paymentMethodSplitPaise,
    required this.last7DaysSales,
    required this.topProducts,
    required this.expenseCategoryBreakdownPaise,
  });
}

final reportsDataProvider = FutureProvider.autoDispose<ReportsData>((ref) async {
  final timeRange = ref.watch(selectedReportTimeRangeProvider);
  final dbHelper = ref.watch(databaseHelperProvider);
  final db = await dbHelper.database;
  final custRepo = ref.watch(customerRepositoryProvider);

  final now = DateTime.now();
  int? startTimestamp;

  switch (timeRange) {
    case ReportTimeRange.today:
      startTimestamp =
          DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
      break;
    case ReportTimeRange.last7Days:
      final start = now.subtract(const Duration(days: 6));
      startTimestamp =
          DateTime(start.year, start.month, start.day).millisecondsSinceEpoch;
      break;
    case ReportTimeRange.last30Days:
      final start = now.subtract(const Duration(days: 29));
      startTimestamp =
          DateTime(start.year, start.month, start.day).millisecondsSinceEpoch;
      break;
    case ReportTimeRange.allTime:
      startTimestamp = null;
      break;
  }

  // 1. Sales & Transactions
  String salesWhere = '';
  List<dynamic> salesArgs = [];
  if (startTimestamp != null) {
    salesWhere = 'WHERE created_at >= ?';
    salesArgs = [startTimestamp];
  }

  final salesAgg = await db.rawQuery('''
    SELECT SUM(total_paise) as total, COUNT(*) as count
    FROM sales
    $salesWhere
  ''', salesArgs);

  final totalSales = (salesAgg.isNotEmpty && salesAgg.first['total'] != null)
      ? salesAgg.first['total'] as int
      : 0;
  final totalTransactions = (salesAgg.isNotEmpty && salesAgg.first['count'] != null)
      ? salesAgg.first['count'] as int
      : 0;

  // 2. Purchases (Inward stock bills)
  String purWhere = '';
  List<dynamic> purArgs = [];
  if (startTimestamp != null) {
    purWhere = 'WHERE date >= ?';
    purArgs = [startTimestamp];
  }
  final purAgg = await db.rawQuery('''
    SELECT SUM(total_paise) as total
    FROM purchases
    $purWhere
  ''', purArgs);
  final totalPurchases = (purAgg.isNotEmpty && purAgg.first['total'] != null)
      ? purAgg.first['total'] as int
      : 0;

  // 3. Expenses
  String expWhere = '';
  List<dynamic> expArgs = [];
  if (startTimestamp != null) {
    expWhere = 'WHERE date >= ?';
    expArgs = [startTimestamp];
  }
  final expAgg = await db.rawQuery('''
    SELECT SUM(amount_paise) as total
    FROM expenses
    $expWhere
  ''', expArgs);
  final totalExpenses = (expAgg.isNotEmpty && expAgg.first['total'] != null)
      ? expAgg.first['total'] as int
      : 0;

  // 4. Net Profit = Sales - Expenses (or gross sales minus expenses)
  final netProfit = totalSales - totalExpenses;

  // 5. Outstanding Udhaar
  final udhaar = await custRepo.getTotalOutstandingUdhaar();

  // 6. Payment Method Split
  final paySplitRows = await db.rawQuery('''
    SELECT payment_method, SUM(total_paise) as method_total
    FROM sales
    $salesWhere
    GROUP BY payment_method
  ''', salesArgs);

  final paymentSplit = <String, int>{'Cash': 0, 'UPI': 0, 'Credit': 0};
  for (final row in paySplitRows) {
    final method = row['payment_method'] as String? ?? 'Cash';
    final amt = row['method_total'] as int? ?? 0;
    paymentSplit[method] = amt;
  }

  // 7. Last 7 Days Sales Trend
  final last7Days = <DailySalesDataPoint>[];
  for (int i = 6; i >= 0; i--) {
    final day = now.subtract(Duration(days: i));
    final dayStart = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
    final dayEnd = DateTime(day.year, day.month, day.day, 23, 59, 59, 999).millisecondsSinceEpoch;

    final dayResult = await db.rawQuery('''
      SELECT SUM(total_paise) as day_total
      FROM sales
      WHERE created_at >= ? AND created_at <= ?
    ''', [dayStart, dayEnd]);

    final dayTotal = (dayResult.isNotEmpty && dayResult.first['day_total'] != null)
        ? dayResult.first['day_total'] as int
        : 0;

    last7Days.add(DailySalesDataPoint(
      dayLabel: DateFormat('E').format(day), // Mon, Tue, etc.
      totalSalesPaise: dayTotal,
      date: day,
    ));
  }

  // 8. Top Selling Products
  String itemWhere = '';
  List<dynamic> itemArgs = [];
  if (startTimestamp != null) {
    itemWhere = 'WHERE s.created_at >= ?';
    itemArgs = [startTimestamp];
  }
  final topItemsRows = await db.rawQuery('''
    SELECT si.product_name, SUM(si.quantity) as total_qty, SUM(si.subtotal_paise) as total_rev
    FROM sale_items si
    JOIN sales s ON si.sale_id = s.id
    $itemWhere
    GROUP BY si.product_name
    ORDER BY total_rev DESC
    LIMIT 5
  ''', itemArgs);

  final topProducts = topItemsRows.map((r) {
    return TopSellingProduct(
      productName: r['product_name'] as String? ?? 'Item',
      unitsSold: r['total_qty'] as int? ?? 0,
      totalRevenuePaise: r['total_rev'] as int? ?? 0,
    );
  }).toList();

  // 9. Expense Category Breakdown
  final expCatRows = await db.rawQuery('''
    SELECT category, SUM(amount_paise) as cat_total
    FROM expenses
    $expWhere
    GROUP BY category
    ORDER BY cat_total DESC
  ''', expArgs);

  final expenseCategoryBreakdown = <String, int>{};
  for (final row in expCatRows) {
    final cat = row['category'] as String? ?? 'General';
    final amt = row['cat_total'] as int? ?? 0;
    expenseCategoryBreakdown[cat] = amt;
  }

  return ReportsData(
    totalSalesPaise: totalSales,
    totalPurchasesPaise: totalPurchases,
    totalExpensesPaise: totalExpenses,
    netProfitPaise: netProfit,
    outstandingUdhaarPaise: udhaar,
    totalTransactions: totalTransactions,
    paymentMethodSplitPaise: paymentSplit,
    last7DaysSales: last7Days,
    topProducts: topProducts,
    expenseCategoryBreakdownPaise: expenseCategoryBreakdown,
  );
});

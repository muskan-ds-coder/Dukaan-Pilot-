import '../entities/sale.dart';

abstract class SaleRepository {
  Future<List<Sale>> getSales({DateTime? startDate, DateTime? endDate, int limit = 50});
  Future<Sale?> getSaleById(String id);
  Future<Sale> createSale({
    String? customerId,
    required List<SaleItem> items,
    int discountPaise = 0,
    required String paymentMethod,
    int? receivedAmountPaise,
    int? udhaarAmountPaise,
    String? notes,
  });
  Future<int> getTodaySalesTotal();
  Future<int> getTodayTransactionCount();
}

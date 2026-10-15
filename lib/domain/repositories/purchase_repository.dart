import '../entities/purchase.dart';

abstract class PurchaseRepository {
  Future<List<Purchase>> getPurchases({
    DateTime? startDate,
    DateTime? endDate,
    String? supplierId,
    int limit = 50,
  });

  Future<Purchase?> getPurchaseById(String id);

  Future<Purchase> createPurchase({
    String? supplierId,
    String? invoiceNumber,
    required List<PurchaseItem> items,
    String paymentStatus = 'PAID',
    DateTime? date,
    String? notes,
  });

  Future<int> getTotalPurchasesPaise({DateTime? startDate, DateTime? endDate});
  Future<int> getPurchasesCount({DateTime? startDate, DateTime? endDate});
}

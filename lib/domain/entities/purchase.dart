/// Line item in a supplier purchase
class PurchaseItem {
  final String id;
  final String purchaseId;
  final String productId;
  final String productName;
  final int quantity;
  final int unitPricePaise;
  final int subtotalPaise;

  const PurchaseItem({
    required this.id,
    required this.purchaseId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPricePaise,
    required this.subtotalPaise,
  });
}

/// Wholesale purchase / inward inventory invoice
class Purchase {
  final String id;
  final String businessId;
  final String? supplierId;
  final String? supplierName;
  final String? invoiceNumber;
  final List<PurchaseItem> items;
  final int totalPaise;
  final String paymentStatus; // PAID, PENDING, PARTIAL
  final DateTime date;
  final String? notes;
  final DateTime createdAt;
  final String syncStatus;

  const Purchase({
    required this.id,
    required this.businessId,
    this.supplierId,
    this.supplierName,
    this.invoiceNumber,
    required this.items,
    required this.totalPaise,
    this.paymentStatus = 'PAID',
    required this.date,
    this.notes,
    required this.createdAt,
    this.syncStatus = 'PENDING',
  });
}

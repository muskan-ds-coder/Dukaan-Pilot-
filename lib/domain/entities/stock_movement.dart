/// Auditable immutable stock movement record
class StockMovement {
  final String id;
  final String businessId;
  final String productId;
  final String? productName;
  final String type;
  final int quantity;
  final int previousStock;
  final int newStock;
  final String? referenceId; // saleId or purchaseId
  final String? note;
  final DateTime createdAt;
  final String? createdBy;
  final String syncStatus;

  const StockMovement({
    required this.id,
    required this.businessId,
    required this.productId,
    this.productName,
    required this.type,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    this.referenceId,
    this.note,
    required this.createdAt,
    this.createdBy,
    this.syncStatus = 'PENDING',
  });

  StockMovement copyWith({
    String? id,
    String? businessId,
    String? productId,
    String? productName,
    String? type,
    int? quantity,
    int? previousStock,
    int? newStock,
    String? referenceId,
    String? note,
    DateTime? createdAt,
    String? createdBy,
    String? syncStatus,
  }) {
    return StockMovement(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      previousStock: previousStock ?? this.previousStock,
      newStock: newStock ?? this.newStock,
      referenceId: referenceId ?? this.referenceId,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

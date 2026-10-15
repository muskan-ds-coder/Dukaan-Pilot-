import '../../domain/entities/stock_movement.dart';

class StockMovementModel extends StockMovement {
  const StockMovementModel({
    required super.id,
    required super.businessId,
    required super.productId,
    super.productName,
    required super.type,
    required super.quantity,
    required super.previousStock,
    required super.newStock,
    super.referenceId,
    super.note,
    required super.createdAt,
    super.createdBy,
    super.syncStatus = 'PENDING',
  });

  factory StockMovementModel.fromEntity(StockMovement entity) {
    return StockMovementModel(
      id: entity.id,
      businessId: entity.businessId,
      productId: entity.productId,
      productName: entity.productName,
      type: entity.type,
      quantity: entity.quantity,
      previousStock: entity.previousStock,
      newStock: entity.newStock,
      referenceId: entity.referenceId,
      note: entity.note,
      createdAt: entity.createdAt,
      createdBy: entity.createdBy,
      syncStatus: entity.syncStatus,
    );
  }

  factory StockMovementModel.fromMap(Map<String, dynamic> map, {String? productName}) {
    return StockMovementModel(
      id: map['id'] as String,
      businessId: map['business_id'] as String,
      productId: map['product_id'] as String,
      productName: productName ?? (map['product_name'] as String?),
      type: map['type'] as String,
      quantity: map['quantity'] as int,
      previousStock: map['previous_stock'] as int,
      newStock: map['new_stock'] as int,
      referenceId: map['reference_id'] as String?,
      note: map['note'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      createdBy: map['created_by'] as String?,
      syncStatus: (map['sync_status'] as String?) ?? 'PENDING',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'product_id': productId,
      'type': type,
      'quantity': quantity,
      'previous_stock': previousStock,
      'new_stock': newStock,
      'reference_id': referenceId,
      'note': note,
      'created_at': createdAt.millisecondsSinceEpoch,
      'created_by': createdBy,
      'sync_status': syncStatus,
    };
  }
}

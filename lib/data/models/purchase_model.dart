import '../../domain/entities/purchase.dart';

class PurchaseItemModel extends PurchaseItem {
  const PurchaseItemModel({
    required super.id,
    required super.purchaseId,
    required super.productId,
    required super.productName,
    required super.quantity,
    required super.unitPricePaise,
    required super.subtotalPaise,
  });

  factory PurchaseItemModel.fromEntity(PurchaseItem entity) {
    return PurchaseItemModel(
      id: entity.id,
      purchaseId: entity.purchaseId,
      productId: entity.productId,
      productName: entity.productName,
      quantity: entity.quantity,
      unitPricePaise: entity.unitPricePaise,
      subtotalPaise: entity.subtotalPaise,
    );
  }

  factory PurchaseItemModel.fromMap(Map<String, dynamic> map) {
    return PurchaseItemModel(
      id: map['id'] as String,
      purchaseId: map['purchase_id'] as String,
      productId: map['product_id'] as String,
      productName: map['product_name'] as String,
      quantity: map['quantity'] as int,
      unitPricePaise: map['unit_price_paise'] as int,
      subtotalPaise: map['subtotal_paise'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'purchase_id': purchaseId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price_paise': unitPricePaise,
      'subtotal_paise': subtotalPaise,
    };
  }
}

class PurchaseModel extends Purchase {
  const PurchaseModel({
    required super.id,
    required super.businessId,
    super.supplierId,
    super.supplierName,
    super.invoiceNumber,
    required super.items,
    required super.totalPaise,
    super.paymentStatus = 'PAID',
    required super.date,
    super.notes,
    required super.createdAt,
    super.syncStatus = 'PENDING',
  });

  factory PurchaseModel.fromEntity(Purchase entity) {
    return PurchaseModel(
      id: entity.id,
      businessId: entity.businessId,
      supplierId: entity.supplierId,
      supplierName: entity.supplierName,
      invoiceNumber: entity.invoiceNumber,
      items: entity.items,
      totalPaise: entity.totalPaise,
      paymentStatus: entity.paymentStatus,
      date: entity.date,
      notes: entity.notes,
      createdAt: entity.createdAt,
      syncStatus: entity.syncStatus,
    );
  }

  factory PurchaseModel.fromMap(Map<String, dynamic> map, {List<PurchaseItem> items = const []}) {
    return PurchaseModel(
      id: map['id'] as String,
      businessId: map['business_id'] as String,
      supplierId: map['supplier_id'] as String?,
      supplierName: map['supplier_name'] as String?,
      invoiceNumber: map['invoice_number'] as String?,
      items: items,
      totalPaise: map['total_paise'] as int,
      paymentStatus: (map['payment_status'] as String?) ?? 'PAID',
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      syncStatus: (map['sync_status'] as String?) ?? 'PENDING',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'supplier_id': supplierId,
      'invoice_number': invoiceNumber,
      'total_paise': totalPaise,
      'payment_status': paymentStatus,
      'date': date.millisecondsSinceEpoch,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'sync_status': syncStatus,
    };
  }
}

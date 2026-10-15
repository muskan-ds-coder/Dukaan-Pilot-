import '../../domain/entities/sale.dart';

class SaleItemModel extends SaleItem {
  const SaleItemModel({
    required super.id,
    required super.saleId,
    required super.productId,
    required super.productName,
    required super.quantity,
    required super.unitPricePaise,
    required super.subtotalPaise,
  });

  factory SaleItemModel.fromEntity(SaleItem entity) {
    return SaleItemModel(
      id: entity.id,
      saleId: entity.saleId,
      productId: entity.productId,
      productName: entity.productName,
      quantity: entity.quantity,
      unitPricePaise: entity.unitPricePaise,
      subtotalPaise: entity.subtotalPaise,
    );
  }

  factory SaleItemModel.fromMap(Map<String, dynamic> map) {
    return SaleItemModel(
      id: map['id'] as String,
      saleId: map['sale_id'] as String,
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
      'sale_id': saleId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price_paise': unitPricePaise,
      'subtotal_paise': subtotalPaise,
    };
  }
}

class SaleModel extends Sale {
  const SaleModel({
    required super.id,
    required super.businessId,
    super.customerId,
    super.customerName,
    required super.items,
    required super.subtotalPaise,
    super.discountPaise = 0,
    required super.totalPaise,
    super.paymentMethod = 'Cash',
    super.notes,
    required super.createdAt,
    super.syncStatus = 'PENDING',
  });

  factory SaleModel.fromEntity(Sale entity) {
    return SaleModel(
      id: entity.id,
      businessId: entity.businessId,
      customerId: entity.customerId,
      customerName: entity.customerName,
      items: entity.items,
      subtotalPaise: entity.subtotalPaise,
      discountPaise: entity.discountPaise,
      totalPaise: entity.totalPaise,
      paymentMethod: entity.paymentMethod,
      notes: entity.notes,
      createdAt: entity.createdAt,
      syncStatus: entity.syncStatus,
    );
  }

  factory SaleModel.fromMap(Map<String, dynamic> map, {List<SaleItem> items = const [], String? customerName}) {
    return SaleModel(
      id: map['id'] as String,
      businessId: map['business_id'] as String,
      customerId: map['customer_id'] as String?,
      customerName: customerName ?? (map['customer_name'] as String?),
      items: items,
      subtotalPaise: map['subtotal_paise'] as int,
      discountPaise: (map['discount_paise'] as int?) ?? 0,
      totalPaise: map['total_paise'] as int,
      paymentMethod: (map['payment_method'] as String?) ?? 'Cash',
      notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      syncStatus: (map['sync_status'] as String?) ?? 'PENDING',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'customer_id': customerId,
      'subtotal_paise': subtotalPaise,
      'discount_paise': discountPaise,
      'total_paise': totalPaise,
      'payment_method': paymentMethod,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'sync_status': syncStatus,
    };
  }
}

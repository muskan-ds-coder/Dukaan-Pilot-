/// Individual item within a sale
class SaleItem {
  final String id;
  final String saleId;
  final String productId;
  final String productName;
  final int quantity;
  final int unitPricePaise;
  final int subtotalPaise;

  const SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPricePaise,
    required this.subtotalPaise,
  });

  SaleItem copyWith({
    String? id,
    String? saleId,
    String? productId,
    String? productName,
    int? quantity,
    int? unitPricePaise,
    int? subtotalPaise,
  }) {
    return SaleItem(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPricePaise: unitPricePaise ?? this.unitPricePaise,
      subtotalPaise: subtotalPaise ?? this.subtotalPaise,
    );
  }
}

/// Sale transaction entity
class Sale {
  final String id;
  final String businessId;
  final String? customerId;
  final String? customerName;
  final List<SaleItem> items;
  final int subtotalPaise;
  final int discountPaise;
  final int totalPaise;
  final String paymentMethod;
  final String? notes;
  final DateTime createdAt;
  final String syncStatus;

  const Sale({
    required this.id,
    required this.businessId,
    this.customerId,
    this.customerName,
    required this.items,
    required this.subtotalPaise,
    this.discountPaise = 0,
    required this.totalPaise,
    this.paymentMethod = 'Cash',
    this.notes,
    required this.createdAt,
    this.syncStatus = 'PENDING',
  });

  Sale copyWith({
    String? id,
    String? businessId,
    String? customerId,
    String? customerName,
    List<SaleItem>? items,
    int? subtotalPaise,
    int? discountPaise,
    int? totalPaise,
    String? paymentMethod,
    String? notes,
    DateTime? createdAt,
    String? syncStatus,
  }) {
    return Sale(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      subtotalPaise: subtotalPaise ?? this.subtotalPaise,
      discountPaise: discountPaise ?? this.discountPaise,
      totalPaise: totalPaise ?? this.totalPaise,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

enum StockStatus {
  healthy,
  low,
  outOfStock,
}

/// Product SKU and inventory entity
class Product {
  final String id;
  final String businessId;
  final String name;
  final String? category;
  final String? brand;
  final String? sku;
  final String? barcode;
  final int purchasePricePaise;
  final int sellingPricePaise;
  final int stockQuantity;
  final int minimumStock;
  final String unit;
  final String? supplierId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String syncStatus;

  const Product({
    required this.id,
    required this.businessId,
    required this.name,
    this.category,
    this.brand,
    this.sku,
    this.barcode,
    required this.purchasePricePaise,
    required this.sellingPricePaise,
    required this.stockQuantity,
    this.minimumStock = 5,
    this.unit = 'Piece',
    this.supplierId,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.syncStatus = 'PENDING',
  });

  StockStatus get stockStatus {
    if (stockQuantity <= 0) return StockStatus.outOfStock;
    if (stockQuantity <= minimumStock) return StockStatus.low;
    return StockStatus.healthy;
  }

  /// Reorder formula: max(minimumStock * 2 - stockQuantity, 0)
  int get suggestedReorderQuantity {
    final qty = (minimumStock * 2) - stockQuantity;
    return qty > 0 ? qty : 0;
  }

  /// Unit profit in paise
  int get profitPaise => sellingPricePaise - purchasePricePaise;

  /// Gross profit margin percentage
  double get profitMarginPercentage {
    if (sellingPricePaise <= 0) return 0.0;
    return ((sellingPricePaise - purchasePricePaise) / sellingPricePaise) * 100.0;
  }

  /// Total inventory asset valuation based on cost price
  int get stockValuationPaise => (stockQuantity > 0 ? stockQuantity : 0) * purchasePricePaise;

  /// Total potential revenue based on selling price
  int get retailValuationPaise => (stockQuantity > 0 ? stockQuantity : 0) * sellingPricePaise;

  Product copyWith({
    String? id,
    String? businessId,
    String? name,
    String? category,
    String? brand,
    String? sku,
    String? barcode,
    int? purchasePricePaise,
    int? sellingPricePaise,
    int? stockQuantity,
    int? minimumStock,
    String? unit,
    String? supplierId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? syncStatus,
  }) {
    return Product(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      purchasePricePaise: purchasePricePaise ?? this.purchasePricePaise,
      sellingPricePaise: sellingPricePaise ?? this.sellingPricePaise,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minimumStock: minimumStock ?? this.minimumStock,
      unit: unit ?? this.unit,
      supplierId: supplierId ?? this.supplierId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

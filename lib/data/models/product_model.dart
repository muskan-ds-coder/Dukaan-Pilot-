import '../../domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.businessId,
    required super.name,
    super.category,
    super.brand,
    super.sku,
    super.barcode,
    required super.purchasePricePaise,
    required super.sellingPricePaise,
    required super.stockQuantity,
    super.minimumStock = 5,
    super.unit = 'Piece',
    super.supplierId,
    required super.createdAt,
    required super.updatedAt,
    super.isActive = true,
    super.syncStatus = 'PENDING',
  });

  factory ProductModel.fromEntity(Product entity) {
    return ProductModel(
      id: entity.id,
      businessId: entity.businessId,
      name: entity.name,
      category: entity.category,
      brand: entity.brand,
      sku: entity.sku,
      barcode: entity.barcode,
      purchasePricePaise: entity.purchasePricePaise,
      sellingPricePaise: entity.sellingPricePaise,
      stockQuantity: entity.stockQuantity,
      minimumStock: entity.minimumStock,
      unit: entity.unit,
      supplierId: entity.supplierId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isActive: entity.isActive,
      syncStatus: entity.syncStatus,
    );
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as String,
      businessId: map['business_id'] as String,
      name: map['name'] as String,
      category: map['category'] as String?,
      brand: map['brand'] as String?,
      sku: map['sku'] as String?,
      barcode: map['barcode'] as String?,
      purchasePricePaise: map['purchase_price_paise'] as int,
      sellingPricePaise: map['selling_price_paise'] as int,
      stockQuantity: map['stock_quantity'] as int,
      minimumStock: (map['minimum_stock'] as int?) ?? 5,
      unit: (map['unit'] as String?) ?? 'Piece',
      supplierId: map['supplier_id'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      isActive: (map['is_active'] as int? ?? 1) == 1,
      syncStatus: (map['sync_status'] as String?) ?? 'PENDING',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      'category': category,
      'brand': brand,
      'sku': sku,
      'barcode': barcode,
      'purchase_price_paise': purchasePricePaise,
      'selling_price_paise': sellingPricePaise,
      'stock_quantity': stockQuantity,
      'minimum_stock': minimumStock,
      'unit': unit,
      'supplier_id': supplierId,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'is_active': isActive ? 1 : 0,
      'sync_status': syncStatus,
    };
  }
}

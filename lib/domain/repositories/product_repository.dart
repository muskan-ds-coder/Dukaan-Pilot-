import '../entities/product.dart';
import '../entities/stock_movement.dart';

enum ProductSortOption {
  nameAsc,
  nameDesc,
  stockAsc,
  stockDesc,
  priceAsc,
  priceDesc,
  recentlyUpdated,
}

abstract class ProductRepository {
  Future<List<Product>> getProducts({
    String? query,
    String? category,
    bool? onlyLowStock,
    ProductSortOption sort = ProductSortOption.nameAsc,
  });
  Future<Product?> getProductById(String id);
  Future<Product> addProduct(Product product);
  Future<Product> updateProduct(Product product);
  Future<void> archiveProduct(String id);
  Future<void> recordStockMovement(StockMovement movement);
  Future<List<StockMovement>> getStockMovements({
    String? productId,
    String? movementType,
    int limit = 50,
  });
  Future<List<Product>> getLowStockProducts();
  Future<List<String>> getCategories();
  Future<int> getTotalInventoryValuationPaise();
  Future<int> getTotalInventoryUnits();
  Future<Map<String, int>> getStockMovementSummary();
}

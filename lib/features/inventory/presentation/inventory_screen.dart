import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/stock_movement.dart';
import '../../../domain/repositories/product_repository.dart';
import '../../dashboard/providers/dashboard_provider.dart';

final inventorySearchQueryProvider = StateProvider<String>((ref) => '');
final inventoryFilterProvider = StateProvider<String>((ref) => 'All');
final inventorySortProvider =
    StateProvider<ProductSortOption>((ref) => ProductSortOption.nameAsc);

final inventoryCategoriesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getCategories();
});

final inventoryValuationProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  final valuation = await repo.getTotalInventoryValuationPaise();
  final units = await repo.getTotalInventoryUnits();
  return {'valuation': valuation, 'units': units};
});

final inventoryProductsProvider = productsListProvider;

final productsListProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  final query = ref.watch(inventorySearchQueryProvider);
  final filter = ref.watch(inventoryFilterProvider);
  final sort = ref.watch(inventorySortProvider);
  final repo = ref.watch(productRepositoryProvider);

  bool? onlyLowStock;
  String? categoryFilter;

  if (filter == 'Low Stock') {
    onlyLowStock = true;
  } else if (filter != 'All' && filter != 'Out of Stock' && filter != 'Healthy') {
    categoryFilter = filter;
  }

  final list = await repo.getProducts(
    query: query.isEmpty ? null : query,
    category: categoryFilter,
    onlyLowStock: onlyLowStock,
    sort: sort,
  );

  if (filter == 'Out of Stock') {
    return list.where((p) => p.stockQuantity <= 0).toList();
  } else if (filter == 'Healthy') {
    return list.where((p) => p.stockQuantity > p.minimumStock).toList();
  }
  return list;
});

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(productsListProvider);
    final selectedFilter = ref.watch(inventoryFilterProvider);
    final selectedSort = ref.watch(inventorySortProvider);
    final valuationAsync = ref.watch(inventoryValuationProvider);
    final categoriesAsync = ref.watch(inventoryCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory & Stock'),
        actions: [
          IconButton(
            icon: const Icon(Icons.warning_amber_rounded),
            tooltip: 'Low Stock Alerts',
            onPressed: () => context.push('/low-stock'),
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Stock Movement Audit Log',
            onPressed: () => context.push('/stock-movements'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-product'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_box_rounded),
        label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // Total Stock Valuation Header Card
          valuationAsync.when(
            data: (val) {
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL STOCK VALUATION',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.formatPaise(val['valuation'] ?? 0),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'IN-STOCK UNITS',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${val['units'] ?? 0} units',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF818CF8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          // Search Bar & Sort Dropdown Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search products by name, brand, barcode...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: ref.watch(inventorySearchQueryProvider).isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () =>
                                  ref.read(inventorySearchQueryProvider.notifier).state = '',
                            )
                          : null,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (val) {
                      ref.read(inventorySearchQueryProvider.notifier).state = val;
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Sort Menu Button
                PopupMenuButton<ProductSortOption>(
                  icon: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                    child: Icon(Icons.sort_rounded, color: theme.colorScheme.primary),
                  ),
                  tooltip: 'Sort Products',
                  initialValue: selectedSort,
                  onSelected: (option) {
                    ref.read(inventorySortProvider.notifier).state = option;
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: ProductSortOption.nameAsc,
                      child: Text('Name: A to Z'),
                    ),
                    const PopupMenuItem(
                      value: ProductSortOption.nameDesc,
                      child: Text('Name: Z to A'),
                    ),
                    const PopupMenuItem(
                      value: ProductSortOption.stockAsc,
                      child: Text('Stock: Low to High'),
                    ),
                    const PopupMenuItem(
                      value: ProductSortOption.stockDesc,
                      child: Text('Stock: High to Low'),
                    ),
                    const PopupMenuItem(
                      value: ProductSortOption.priceAsc,
                      child: Text('Price: Low to High'),
                    ),
                    const PopupMenuItem(
                      value: ProductSortOption.priceDesc,
                      child: Text('Price: High to Low'),
                    ),
                    const PopupMenuItem(
                      value: ProductSortOption.recentlyUpdated,
                      child: Text('Recently Updated'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _FilterChip(label: 'All'),
                const SizedBox(width: 8),
                _FilterChip(label: 'Healthy', color: const Color(0xFF0D9488)),
                const SizedBox(width: 8),
                _FilterChip(label: 'Low Stock', color: const Color(0xFFF97316)),
                const SizedBox(width: 8),
                _FilterChip(label: 'Out of Stock', color: const Color(0xFFDC2626)),
                // Dynamic Categories
                ...categoriesAsync.maybeWhen(
                  data: (cats) => cats.map((cat) => Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: _FilterChip(label: cat),
                      )),
                  orElse: () => [],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Product List
          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            selectedFilter == 'All'
                                ? 'Your inventory is empty'
                                : 'No products in this filter',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add items to track stock, prices, profit margins, and low-inventory warnings.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/add-product'),
                            icon: const Icon(Icons.add),
                            label: const Text('Add First Product'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                  itemCount: products.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _ProductCard(
                      product: product,
                      onTap: () => context.push('/products/${product.id}'),
                      onAdjustStock: () => _showAdjustStockDialog(context, ref, product),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading inventory: $err')),
            ),
          ),
        ],
      ),
    );
  }

  void _showAdjustStockDialog(BuildContext context, WidgetRef ref, Product product) {
    final qtyController = TextEditingController();
    String movementType = AppConstants.movementAdjustmentIn;
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Adjust Stock: ${product.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Stock: ${product.stockQuantity} ${product.unit}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: movementType,
                  decoration: const InputDecoration(labelText: 'Adjustment Type *'),
                  items: [
                    DropdownMenuItem(
                      value: AppConstants.movementAdjustmentIn,
                      child: const Text('Add Stock (Stock In)'),
                    ),
                    DropdownMenuItem(
                      value: AppConstants.movementAdjustmentOut,
                      child: const Text('Reduce Stock (Stock Out)'),
                    ),
                    DropdownMenuItem(
                      value: AppConstants.movementDamage,
                      child: const Text('Damaged / Expired Item'),
                    ),
                    DropdownMenuItem(
                      value: AppConstants.movementReturnIn,
                      child: const Text('Customer Return (Return In)'),
                    ),
                    DropdownMenuItem(
                      value: AppConstants.movementReturnOut,
                      child: const Text('Supplier Return (Return Out)'),
                    ),
                    DropdownMenuItem(
                      value: AppConstants.movementCorrection,
                      child: const Text('Direct Stock Correction'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => movementType = val);
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: movementType == AppConstants.movementCorrection
                        ? 'Exact Count After Verification'
                        : 'Quantity to Adjust *',
                    prefixIcon: const Icon(Icons.numbers),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Reason / Note (Optional)',
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final qty = int.tryParse(qtyController.text.trim()) ?? 0;
                if (qty <= 0 && movementType != AppConstants.movementCorrection) {
                  return;
                }
                Navigator.pop(dialogCtx);
                try {
                  final repo = ref.read(productRepositoryProvider);
                  await repo.recordStockMovement(
                    StockMovement(
                      id: '',
                      businessId: product.businessId,
                      productId: product.id,
                      type: movementType,
                      quantity: qty,
                      previousStock: product.stockQuantity,
                      newStock: 0,
                      note: noteController.text.trim(),
                      createdAt: DateTime.now(),
                    ),
                  );

                  ref.invalidate(productsListProvider);
                  ref.invalidate(inventoryValuationProvider);
                  ref.invalidate(dashboardMetricsProvider);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Stock updated & auditable movement recorded.'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
              },
              child: const Text('Confirm Adjustment'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends ConsumerWidget {
  final String label;
  final Color? color;

  const _FilterChip({required this.label, this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(inventoryFilterProvider) == label;
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        ref.read(inventoryFilterProvider.notifier).state = label;
      },
      selectedColor: (color ?? theme.colorScheme.primary).withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected
            ? (color ?? theme.colorScheme.primary)
            : theme.colorScheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAdjustStock;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onAdjustStock,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color badgeColor;
    String badgeText;
    switch (product.stockStatus) {
      case StockStatus.outOfStock:
        badgeColor = const Color(0xFFDC2626);
        badgeText = 'OUT OF STOCK';
        break;
      case StockStatus.low:
        badgeColor = const Color(0xFFF97316);
        badgeText = 'LOW STOCK (${product.stockQuantity})';
        break;
      case StockStatus.healthy:
        badgeColor = const Color(0xFF0D9488);
        badgeText = 'HEALTHY';
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      if (product.brand != null || product.category != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${product.brand ?? ""} • ${product.category ?? ""}',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selling Price',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatPaise(product.sellingPricePaise),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cost Price',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatPaise(product.purchasePricePaise),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Stock',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    Text(
                      '${product.stockQuantity} ${product.unit}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded),
                  tooltip: 'Adjust Stock',
                  onPressed: onAdjustStock,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

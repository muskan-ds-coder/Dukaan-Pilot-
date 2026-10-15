import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/database_provider.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/stock_movement.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import 'inventory_screen.dart';

final lowStockProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getLowStockProducts();
});

class LowStockScreen extends ConsumerWidget {
  const LowStockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lowStockAsync = ref.watch(lowStockProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Low Stock Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(lowStockProductsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Recommendation Explanation Banner (Section 23)
          Container(
            padding: const EdgeInsets.all(14),
            color: const Color(0xFFF97316).withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFFEA580C), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Suggested reorder quantities are calculated as max(2 × minStock - currentStock, 0). This is a simple inventory rule recommendation, not an AI prediction.',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: lowStockAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified_rounded,
                              size: 56,
                              color: Color(0xFF0D9488),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'All inventory levels healthy!',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'No items are at or below their minimum stock threshold.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: products.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final p = products[index];
                    final isOutOfStock = p.stockQuantity <= 0;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isOutOfStock
                              ? const Color(0xFFDC2626).withValues(alpha: 0.5)
                              : const Color(0xFFF97316).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (isOutOfStock
                                          ? const Color(0xFFDC2626)
                                          : const Color(0xFFF97316))
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isOutOfStock ? 'OUT OF STOCK' : 'LOW STOCK',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: isOutOfStock
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFFF97316),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${p.brand ?? "No Brand"} • ${p.category ?? "General"}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current Stock',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          theme.colorScheme.onSurface.withValues(alpha: 0.55),
                                    ),
                                  ),
                                  Text(
                                    '${p.stockQuantity} ${p.unit}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: isOutOfStock
                                          ? const Color(0xFFDC2626)
                                          : const Color(0xFFF97316),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Min Stock Level',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          theme.colorScheme.onSurface.withValues(alpha: 0.55),
                                    ),
                                  ),
                                  Text(
                                    '${p.minimumStock} ${p.unit}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Suggested Reorder',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color:
                                          theme.colorScheme.onSurface.withValues(alpha: 0.55),
                                    ),
                                  ),
                                  Text(
                                    '+${p.suggestedReorderQuantity} ${p.unit}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: Color(0xFF0D9488),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Quick Action: Add Stock or view product
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => context.push('/products/${p.id}'),
                                child: const Text('View Product'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () => _showQuickRestockDialog(context, ref, p),
                                icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                                label: const Text('Restock Now'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D9488),
                                  minimumSize: const Size(120, 38),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading low stock items: $err')),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickRestockDialog(BuildContext context, WidgetRef ref, Product product) {
    final qtyController =
        TextEditingController(text: product.suggestedReorderQuantity.toString());

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Restock: ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Stock: ${product.stockQuantity} ${product.unit}'),
            const SizedBox(height: 14),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity Arrived (Purchase / Inward) *',
                prefixIcon: Icon(Icons.add_box_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final qty = int.tryParse(qtyController.text.trim()) ?? 0;
              if (qty <= 0) return;

              Navigator.pop(dialogCtx);
              try {
                final repo = ref.read(productRepositoryProvider);
                await repo.recordStockMovement(
                  StockMovement(
                    id: '',
                    businessId: product.businessId,
                    productId: product.id,
                    type: AppConstants.movementPurchase,
                    quantity: qty,
                    previousStock: product.stockQuantity,
                    newStock: product.stockQuantity + qty,
                    note: 'Restocked from Low Stock screen',
                    createdAt: DateTime.now(),
                  ),
                );

                ref.invalidate(lowStockProductsProvider);
                ref.invalidate(productsListProvider);
                ref.invalidate(dashboardMetricsProvider);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Restocked $qty ${product.unit} of ${product.name}!'),
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
            child: const Text('Confirm Restock'),
          ),
        ],
      ),
    );
  }
}

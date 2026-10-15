import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/stock_movement.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../inventory/presentation/inventory_screen.dart';

final productDetailProvider =
    FutureProvider.family.autoDispose<Product?, String>((ref, productId) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getProductById(productId);
});

final productMovementsProvider =
    FutureProvider.family.autoDispose<List<StockMovement>, String>((ref, productId) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getStockMovements(productId: productId, limit: 30);
});

class ProductDetailScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final productAsync = ref.watch(productDetailProvider(productId));
    final movementsAsync = ref.watch(productMovementsProvider(productId));

    return productAsync.when(
      data: (product) {
        if (product == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Product Detail')),
            body: const Center(child: Text('Product not found.')),
          );
        }

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
            badgeText = 'HEALTHY STOCK';
            break;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(product.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Product',
                onPressed: () => context.push('/edit-product/${product.id}'),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                tooltip: 'Archive Product',
                onPressed: () => _confirmArchive(context, ref, product),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/edit-product/${product.id}'),
                      icon: const Icon(Icons.edit_note_rounded),
                      label: const Text('Edit Details'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showAdjustStockDialog(context, ref, product),
                      icon: const Icon(Icons.sync_alt_rounded),
                      label: const Text('Adjust Stock'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(productDetailProvider(productId));
              ref.invalidate(productMovementsProvider(productId));
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Overview Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(18),
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${product.brand ?? "No Brand"} • ${product.category ?? "General"}',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
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
                        const SizedBox(height: 18),
                        const Divider(height: 1),
                        const SizedBox(height: 16),

                        // Stock Count Display
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Inventory',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${product.stockQuantity} ${product.unit}',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: badgeColor,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Min Stock Alert Level',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${product.minimumStock} ${product.unit}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Low stock recommendation banner
                        if (product.stockStatus != StockStatus.healthy) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF97316).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFF97316).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded,
                                    color: Color(0xFFF97316), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Suggested Reorder: ${product.suggestedReorderQuantity} ${product.unit}\n(Simple recommendation based on 2x threshold)',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFEA580C),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Financial Margins & Pricing Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pricing & Profit Margins',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _DetailKpi(
                                label: 'Selling Price (MRP)',
                                value: CurrencyFormatter.formatPaise(product.sellingPricePaise),
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Expanded(
                              child: _DetailKpi(
                                label: 'Cost Price',
                                value: CurrencyFormatter.formatPaise(product.purchasePricePaise),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _DetailKpi(
                                label: 'Profit / Margin',
                                value:
                                    '${CurrencyFormatter.formatPaise(product.profitPaise)} (${product.profitMarginPercentage.toStringAsFixed(1)}%)',
                                color: product.profitPaise >= 0
                                    ? const Color(0xFF0D9488)
                                    : const Color(0xFFDC2626),
                              ),
                            ),
                            Expanded(
                              child: _DetailKpi(
                                label: 'Stock Asset Value',
                                value: CurrencyFormatter.formatPaise(product.stockValuationPaise),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Identifiers & Codes Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Barcodes & Identifiers',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _DetailKpi(
                                label: 'Barcode',
                                value: product.barcode?.isNotEmpty == true
                                    ? product.barcode!
                                    : 'Not assigned',
                              ),
                            ),
                            Expanded(
                              child: _DetailKpi(
                                label: 'SKU Code',
                                value: product.sku?.isNotEmpty == true ? product.sku! : 'None',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Product Stock Movement History Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Stock Movement History',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => context.push('/stock-movements'),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: const Text('All Movements'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Movements List
                  movementsAsync.when(
                    data: (movements) {
                      if (movements.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: theme.colorScheme.outline.withValues(alpha: 0.6)),
                          ),
                          child: const Center(
                            child: Text('No previous stock adjustments recorded for this product.'),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: movements.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final m = movements[index];
                          final isIncrease = m.newStock > m.previousStock;
                          final dateStr =
                              DateFormat('d MMM y, h:mm a').format(m.createdAt);

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: theme.cardTheme.color,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.colorScheme.outline),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isIncrease
                                      ? const Color(0xFF0D9488).withValues(alpha: 0.12)
                                      : const Color(0xFFDC2626).withValues(alpha: 0.12),
                                  child: Icon(
                                    isIncrease
                                        ? Icons.arrow_downward_rounded
                                        : Icons.arrow_upward_rounded,
                                    size: 18,
                                    color: isIncrease
                                        ? const Color(0xFF0D9488)
                                        : const Color(0xFFDC2626),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.type.replaceAll('_', ' '),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700, fontSize: 13.5),
                                      ),
                                      Text(
                                        'Stock: ${m.previousStock} → ${m.newStock} • $dateStr',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color:
                                              theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                        ),
                                      ),
                                      if (m.note != null && m.note!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          m.note!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.75),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Text(
                                  isIncrease ? '+${m.quantity}' : '-${m.quantity}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: isIncrease
                                        ? const Color(0xFF0D9488)
                                        : const Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, _) => Text('Error loading history: $err'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error loading product details: $err')),
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
                      child: const Text('Damage / Expired Item'),
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
                        ? 'Exact Count After Count'
                        : 'Quantity to Adjust *',
                    prefixIcon: const Icon(Icons.numbers),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Audit Note / Reason (Optional)',
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

                  ref.invalidate(productDetailProvider(product.id));
                  ref.invalidate(productMovementsProvider(product.id));
                  ref.invalidate(productsListProvider);
                  ref.invalidate(dashboardMetricsProvider);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Stock updated & auditable movement recorded.')),
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
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmArchive(BuildContext context, WidgetRef ref, Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive Product'),
        content: Text(
          'Are you sure you want to archive "${product.name}"? It will be hidden from the active catalog and inventory searches, while preserving previous sale audit logs.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final repo = ref.read(productRepositoryProvider);
      await repo.archiveProduct(product.id);

      ref.invalidate(productsListProvider);
      ref.invalidate(dashboardMetricsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product archived.')),
        );
        context.pop();
      }
    }
  }
}

class _DetailKpi extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _DetailKpi({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

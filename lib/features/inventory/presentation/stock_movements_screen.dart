import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/database_provider.dart';
import '../../../domain/entities/stock_movement.dart';

final movementTypeFilterProvider = StateProvider<String>((ref) => 'ALL');

final stockMovementsListProvider =
    FutureProvider.autoDispose<List<StockMovement>>((ref) async {
  final filter = ref.watch(movementTypeFilterProvider);
  final repo = ref.watch(productRepositoryProvider);
  return repo.getStockMovements(movementType: filter, limit: 100);
});

final stockSummaryProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getStockMovementSummary();
});

class StockMovementsScreen extends ConsumerWidget {
  const StockMovementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final movementsAsync = ref.watch(stockMovementsListProvider);
    final summaryAsync = ref.watch(stockSummaryProvider);
    final selectedFilter = ref.watch(movementTypeFilterProvider);

    final movementFilters = [
      'ALL',
      AppConstants.movementPurchase,
      AppConstants.movementSale,
      AppConstants.movementAdjustmentIn,
      AppConstants.movementAdjustmentOut,
      AppConstants.movementDamage,
      AppConstants.movementReturnIn,
      AppConstants.movementReturnOut,
      AppConstants.movementCorrection,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Movement Audit Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(stockMovementsListProvider);
              ref.invalidate(stockSummaryProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Movement Summary KPI Header
          summaryAsync.when(
            data: (summary) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: theme.colorScheme.surface,
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryBox(
                        title: 'Total Stock In',
                        value: '+${summary['totalIn'] ?? 0}',
                        icon: Icons.arrow_downward_rounded,
                        color: const Color(0xFF0D9488),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryBox(
                        title: 'Total Sold',
                        value: '-${summary['totalOut'] ?? 0}',
                        icon: Icons.shopping_bag_outlined,
                        color: const Color(0xFF4F46E5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryBox(
                        title: 'Damaged / Lost',
                        value: '${summary['totalDamaged'] ?? 0}',
                        icon: Icons.warning_amber_rounded,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          // Horizontal Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: movementFilters.map((f) {
                final isSelected = selectedFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(f.replaceAll('_', ' ')),
                    selected: isSelected,
                    onSelected: (_) {
                      ref.read(movementTypeFilterProvider.notifier).state = f;
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),

          // Movements Log List
          Expanded(
            child: movementsAsync.when(
              data: (movements) {
                if (movements.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            selectedFilter == 'ALL'
                                ? 'No stock movements recorded yet'
                                : 'No movements of type "$selectedFilter"',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'All inventory modifications (sales, inward stock, adjustments, damages) are immutably logged here.',
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
                  itemCount: movements.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final m = movements[index];
                    final isPositive = m.newStock > m.previousStock;
                    final dateStr =
                        DateFormat('d MMMM y, h:mm a').format(m.createdAt);

                    Color chipColor;
                    switch (m.type) {
                      case AppConstants.movementPurchase:
                      case AppConstants.movementAdjustmentIn:
                      case AppConstants.movementReturnIn:
                        chipColor = const Color(0xFF0D9488);
                        break;
                      case AppConstants.movementDamage:
                        chipColor = const Color(0xFFDC2626);
                        break;
                      case AppConstants.movementSale:
                      case AppConstants.movementAdjustmentOut:
                      case AppConstants.movementReturnOut:
                        chipColor = const Color(0xFF4F46E5);
                        break;
                      case AppConstants.movementCorrection:
                      default:
                        chipColor = const Color(0xFFF97316);
                        break;
                    }

                    return Container(
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  m.productName ?? 'Product',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: chipColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  m.type.replaceAll('_', ' '),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: chipColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Stock: ${m.previousStock} → ${m.newStock}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                              ),
                              Text(
                                isPositive ? '+${m.quantity}' : '-${m.quantity}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: isPositive
                                      ? const Color(0xFF0D9488)
                                      : const Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                dateStr,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                                ),
                              ),
                              if (m.referenceId != null && m.referenceId!.isNotEmpty)
                                Text(
                                  'Ref: ${m.referenceId}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                          if (m.note != null && m.note!.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Note: ${m.note}',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading movements: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryBox({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

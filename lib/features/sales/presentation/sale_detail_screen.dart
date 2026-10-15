import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/sale.dart';

final saleDetailProvider = FutureProvider.family<Sale?, String>((ref, id) async {
  final repo = ref.watch(saleRepositoryProvider);
  return repo.getSaleById(id);
});

class SaleDetailScreen extends ConsumerWidget {
  final String saleId;
  const SaleDetailScreen({super.key, required this.saleId});

  void _shareReceiptOnWhatsApp(BuildContext context, Sale sale, String businessName) {
    final dateStr = DateFormat('dd/MM/yyyy hh:mm a').format(sale.createdAt);
    final buffer = StringBuffer();
    buffer.writeln('🧾 *INVOICE: ${businessName.toUpperCase()}*');
    buffer.writeln('📅 Date: $dateStr');
    buffer.writeln('🆔 Bill No: #${sale.id.substring(0, 8)}');
    if (sale.customerName != null) {
      buffer.writeln('👤 Customer: ${sale.customerName}');
    }
    buffer.writeln('--------------------------------');
    for (final item in sale.items) {
      final unitPrice = CurrencyFormatter.formatPaise(item.unitPricePaise);
      final subtotal = CurrencyFormatter.formatPaise(item.subtotalPaise);
      buffer.writeln('• ${item.productName} (x${item.quantity} @ $unitPrice) = $subtotal');
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('Subtotal: ${CurrencyFormatter.formatPaise(sale.subtotalPaise)}');
    if (sale.discountPaise > 0) {
      buffer.writeln('Discount: -${CurrencyFormatter.formatPaise(sale.discountPaise)}');
    }
    buffer.writeln('*Grand Total: ${CurrencyFormatter.formatPaise(sale.totalPaise)}*');
    buffer.writeln('Payment: ${sale.paymentMethod}');
    buffer.writeln('\n_Thank you for your business!_ 🙏');

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt copied to clipboard! Ready to paste into WhatsApp.'),
        backgroundColor: Color(0xFF0D9488),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final saleAsync = ref.watch(saleDetailProvider(saleId));
    final business = ref.watch(currentBusinessProvider).value;
    final businessName = business?.name ?? 'DukaanPilot Retail';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale Receipt'),
        actions: [
          saleAsync.when(
            data: (sale) {
              if (sale == null) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.share_rounded),
                tooltip: 'Share Receipt',
                onPressed: () => _shareReceiptOnWhatsApp(context, sale, businessName),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: saleAsync.when(
        data: (sale) {
          if (sale == null) {
            return const Center(child: Text('Sale record not found.'));
          }

          final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(sale.createdAt);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Thermal-style receipt container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outline),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.receipt_rounded, size: 32, color: theme.colorScheme.primary),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              businessName,
                              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                              textAlign: TextAlign.center,
                            ),
                            if (business?.category != null)
                              Text(
                                business!.category,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'PAID & VERIFIED',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: Color(0xFF0D9488),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Divider(height: 1),
                      const SizedBox(height: 14),

                      // Meta details
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Receipt No:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          Text(
                            '#${sale.id.substring(0, 8)}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Date & Time:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          Text(dateStr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Customer:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          Text(
                            sale.customerName ?? 'Walk-in Customer',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: sale.customerName != null ? theme.colorScheme.primary : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Payment Mode:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              sale.paymentMethod,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      // Items Table Header
                      Row(
                        children: const [
                          Expanded(flex: 5, child: Text('ITEM', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Colors.grey))),
                          Expanded(flex: 2, child: Text('QTY', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Colors.grey))),
                          Expanded(flex: 3, child: Text('PRICE', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Colors.grey))),
                          Expanded(flex: 3, child: Text('TOTAL', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Colors.grey))),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Items List
                      ...sale.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5,
                                child: Text(
                                  item.productName,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${item.quantity}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  CurrencyFormatter.formatPaise(item.unitPricePaise),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  CurrencyFormatter.formatPaise(item.subtotalPaise),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      // Totals Summary
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal:', style: TextStyle(fontSize: 14)),
                          Text(CurrencyFormatter.formatPaise(sale.subtotalPaise), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      if (sale.discountPaise > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Discount:', style: TextStyle(fontSize: 14, color: Colors.green)),
                            Text('-${CurrencyFormatter.formatPaise(sale.discountPaise)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.green)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Grand Total:',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            CurrencyFormatter.formatPaise(sale.totalPaise),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),

                      if (sale.notes != null && sale.notes!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Note: ${sale.notes!}',
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Share Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _shareReceiptOnWhatsApp(context, sale, businessName),
                        icon: const Icon(Icons.share_rounded),
                        label: const Text('WhatsApp Share'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Done'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading sale: $err')),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/stock_movement.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../inventory/presentation/inventory_screen.dart';

class ScannedInvoiceItem {
  String name;
  int quantity;
  int unitPricePaise;

  ScannedInvoiceItem({
    required this.name,
    required this.quantity,
    required this.unitPricePaise,
  });

  int get totalPaise => quantity * unitPricePaise;
}

class InvoiceScannerScreen extends ConsumerStatefulWidget {
  const InvoiceScannerScreen({super.key});

  @override
  ConsumerState<InvoiceScannerScreen> createState() => _InvoiceScannerScreenState();
}

class _InvoiceScannerScreenState extends ConsumerState<InvoiceScannerScreen> {
  bool _isProcessing = false;
  bool _hasExtracted = false;

  final _supplierController = TextEditingController(text: 'Hindustan Beauty Distributors');
  final _invoiceNumController = TextEditingController(text: 'INV-2026-8841');
  final List<ScannedInvoiceItem> _scannedItems = [];

  @override
  void dispose() {
    _supplierController.dispose();
    _invoiceNumController.dispose();
    super.dispose();
  }

  void _simulateInvoiceScan() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 1600));

    // Extracted sample vendor invoice rows from OCR
    setState(() {
      _isProcessing = false;
      _hasExtracted = true;
      _scannedItems.clear();
      _scannedItems.addAll([
        ScannedInvoiceItem(name: 'Lakme Face Wash', quantity: 15, unitPricePaise: 12000),
        ScannedInvoiceItem(name: 'Dove Soap 100g', quantity: 24, unitPricePaise: 4500),
        ScannedInvoiceItem(name: 'Nivea Soft Cream', quantity: 10, unitPricePaise: 9000),
      ]);
    });
  }

  int get _invoiceTotalPaise {
    int total = 0;
    for (final item in _scannedItems) {
      total += item.totalPaise;
    }
    return total;
  }

  Future<void> _confirmInvoiceToInventory() async {
    if (_scannedItems.isEmpty) return;

    setState(() => _isProcessing = true);
    final prodRepo = ref.read(productRepositoryProvider);
    final allProducts = await prodRepo.getProducts();

    try {
      // Inward inventory for each item
      for (final item in _scannedItems) {
        Product? match;
        for (final p in allProducts) {
          if (p.name.toLowerCase() == item.name.toLowerCase()) {
            match = p;
            break;
          }
        }

        if (match != null) {
          // Increment stock
          await prodRepo.recordStockMovement(
            StockMovement(
              id: '',
              businessId: match.businessId,
              productId: match.id,
              type: AppConstants.movementPurchase,
              quantity: item.quantity,
              previousStock: match.stockQuantity,
              newStock: match.stockQuantity + item.quantity,
              referenceId: _invoiceNumController.text.trim(),
              note: 'Invoice ${_invoiceNumController.text.trim()} - ${_supplierController.text.trim()}',
              createdAt: DateTime.now(),
            ),
          );
        } else {
          // Auto-create product if not existing
          await prodRepo.addProduct(
            Product(
              id: '',
              businessId: '',
              name: item.name,
              category: 'Cosmetics',
              sellingPricePaise: (item.unitPricePaise * 1.3).round(),
              purchasePricePaise: item.unitPricePaise,
              stockQuantity: item.quantity,
              minimumStock: 5,
              unit: 'Piece',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
        }
      }

      ref.invalidate(dashboardMetricsProvider);
      ref.invalidate(productsListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice confirmed! Inward stock updated in inventory.')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating inward stock: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Bill Scanner'),
        elevation: 0,
      ),
      body: SafeArea(
        child: _isProcessing
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Scanning bill with Google ML Kit OCR...',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_hasExtracted) ...[
                      // Camera viewfinder placeholder
                      Container(
                        height: 260,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: theme.colorScheme.outline),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Align paper bill inside frame',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Extracts supplier, item names, quantities, and cost prices',
                                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _simulateInvoiceScan,
                        icon: const Icon(Icons.document_scanner_rounded),
                        label: const Text('Capture & Scan Invoice'),
                      ),
                    ] else ...[
                      // Editable Review Screen (Section 22)
                      Text(
                        'Review Extracted Invoice',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Verify extracted values before adding inward stock to inventory.',
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.65)),
                      ),
                      const SizedBox(height: 20),

                      // Supplier & Bill Number
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _supplierController,
                              decoration: const InputDecoration(
                                labelText: 'Supplier Name',
                                prefixIcon: Icon(Icons.business_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _invoiceNumController,
                              decoration: const InputDecoration(
                                labelText: 'Invoice #',
                                prefixIcon: Icon(Icons.tag),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Extracted Items Table
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Extracted Items',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          Text(
                            '${_scannedItems.length} items',
                            style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _scannedItems.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _scannedItems[index];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.cardTheme.color,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.colorScheme.outline),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                                      ),
                                      Text(
                                        'Qty: ${item.quantity} • Cost: ${CurrencyFormatter.formatPaise(item.unitPricePaise)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.formatPaise(item.totalPaise),
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Total Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Inward Purchase',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                            Text(
                              CurrencyFormatter.formatPaise(_invoiceTotalPaise),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => setState(() => _hasExtracted = false),
                              child: const Text('Rescan'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _confirmInvoiceToInventory,
                              child: const Text('Confirm to Stock'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

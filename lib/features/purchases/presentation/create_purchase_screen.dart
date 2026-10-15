import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/purchase.dart';
import '../../../domain/entities/supplier.dart';
import '../../inventory/presentation/inventory_screen.dart';
import 'purchases_screen.dart';

class CreatePurchaseScreen extends ConsumerStatefulWidget {
  const CreatePurchaseScreen({super.key});

  @override
  ConsumerState<CreatePurchaseScreen> createState() => _CreatePurchaseScreenState();
}

class _CreatePurchaseScreenState extends ConsumerState<CreatePurchaseScreen> {
  final List<PurchaseItem> _items = [];
  Supplier? _selectedSupplier;
  final _invoiceNumberController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _purchaseDate = DateTime.now();
  String _paymentStatus = 'PAID';
  bool _isLoading = false;

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _totalPaise {
    int sum = 0;
    for (final item in _items) {
      sum += item.subtotalPaise;
    }
    return sum;
  }

  void _openSupplierPicker() async {
    final repo = ref.read(supplierRepositoryProvider);
    final suppliers = await repo.getSuppliers();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Supplier',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showAddSupplierDialog();
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Supplier'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.storefront_outlined)),
              title: const Text('Direct Purchase / General Vendor'),
              subtitle: const Text('No specific supplier record'),
              selected: _selectedSupplier == null,
              onTap: () {
                setState(() => _selectedSupplier = null);
                Navigator.pop(ctx);
              },
            ),
            ...suppliers.map((s) => ListTile(
                  leading: CircleAvatar(
                    child: Text(s.name.substring(0, 1).toUpperCase()),
                  ),
                  title: Text(s.name),
                  subtitle: Text(s.phone ?? s.address ?? 'Wholesale Vendor'),
                  selected: _selectedSupplier?.id == s.id,
                  onTap: () {
                    setState(() => _selectedSupplier = s);
                    Navigator.pop(ctx);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showAddSupplierDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Wholesale Supplier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Supplier / Agency Name *'),
              autofocus: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: addressCtrl,
              decoration: const InputDecoration(labelText: 'City / Address'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final repo = ref.read(supplierRepositoryProvider);
              final newSupplier = await repo.addSupplier(
                Supplier(
                  id: '',
                  businessId: '',
                  name: name,
                  phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                  address: addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : null,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              );
              setState(() => _selectedSupplier = newSupplier);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save & Select'),
          ),
        ],
      ),
    );
  }

  void _openProductPicker() async {
    final repo = ref.read(productRepositoryProvider);
    final products = await repo.getProducts();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Select Product for Inward Stock',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: products.isEmpty
                  ? const Center(child: Text('No products available. Add products first.'))
                  : ListView.separated(
                      controller: scrollController,
                      itemCount: products.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final p = products[index];
                        return ListTile(
                          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            'Current Stock: ${p.stockQuantity} ${p.unit} • Cost: ${CurrencyFormatter.formatPaise(p.purchasePricePaise)}',
                          ),
                          trailing: const Icon(Icons.add_circle_outline),
                          onTap: () {
                            Navigator.pop(ctx);
                            _showAddItemDetailsDialog(p);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddItemDetailsDialog(Product p) {
    final qtyCtrl = TextEditingController(text: '10');
    final costCtrl = TextEditingController(
      text: (p.purchasePricePaise / 100).toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Inward: ${p.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Stock: ${p.stockQuantity} ${p.unit}'),
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Quantity to Inward (${p.unit}) *',
                prefixIcon: const Icon(Icons.add_box_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: costCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Purchase Unit Cost (₹) *',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
              final costPaise = CurrencyFormatter.parseToPaise(costCtrl.text.trim());

              if (qty <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Quantity must be greater than zero.')),
                );
                return;
              }

              setState(() {
                final existingIndex = _items.indexWhere((i) => i.productId == p.id);
                if (existingIndex >= 0) {
                  final existing = _items[existingIndex];
                  final newQty = existing.quantity + qty;
                  _items[existingIndex] = PurchaseItem(
                    id: '',
                    purchaseId: '',
                    productId: p.id,
                    productName: p.name,
                    quantity: newQty,
                    unitPricePaise: costPaise > 0 ? costPaise : existing.unitPricePaise,
                    subtotalPaise: newQty * (costPaise > 0 ? costPaise : existing.unitPricePaise),
                  );
                } else {
                  _items.add(
                    PurchaseItem(
                      id: '',
                      purchaseId: '',
                      productId: p.id,
                      productName: p.name,
                      quantity: qty,
                      unitPricePaise: costPaise,
                      subtotalPaise: qty * costPaise,
                    ),
                  );
                }
              });

              Navigator.pop(ctx);
            },
            child: const Text('Add to Bill'),
          ),
        ],
      ),
    );
  }

  void _confirmPurchase() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product item to inward bill.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(purchaseRepositoryProvider);
      await repo.createPurchase(
        supplierId: _selectedSupplier?.id,
        invoiceNumber: _invoiceNumberController.text.trim().isNotEmpty
            ? _invoiceNumberController.text.trim()
            : null,
        items: _items,
        paymentStatus: _paymentStatus,
        date: _purchaseDate,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      // Invalidate relevant providers to update inventory immediately
      ref.invalidate(purchasesListProvider);
      ref.invalidate(purchasesSummaryProvider);
      ref.invalidate(inventoryProductsProvider);
      ref.invalidate(inventoryValuationProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inward stock bill saved! Inventory updated successfully.'),
          backgroundColor: Color(0xFF0D9488),
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to record purchase: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('dd MMM yyyy').format(_purchaseDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Inward Bill'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Supplier Picker Card
                    InkWell(
                      onTap: _openSupplierPicker,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.colorScheme.outline),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.12),
                              child: const Icon(Icons.storefront_rounded, color: Color(0xFF0F766E)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedSupplier?.name ?? 'Direct Purchase / Vendor',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                  ),
                                  Text(
                                    _selectedSupplier != null
                                        ? (_selectedSupplier!.phone ?? 'Wholesale Supplier')
                                        : 'Tap to link supplier / wholesale agency',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Invoice No & Date
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _invoiceNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Invoice / Bill No.',
                              prefixIcon: Icon(Icons.receipt_long_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _purchaseDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() => _purchaseDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Bill Date',
                                prefixIcon: Icon(Icons.calendar_today_outlined),
                              ),
                              child: Text(dateStr, style: const TextStyle(fontSize: 14)),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Items Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Inward Items (${_items.length})',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        TextButton.icon(
                          onPressed: _openProductPicker,
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          label: const Text('Add SKU'),
                        ),
                      ],
                    ),

                    // Items List or Placeholder
                    if (_items.isEmpty)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.colorScheme.outline),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.add_business_outlined,
                              size: 48,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No items added yet',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap "Add SKU" to select products and quantities received',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: theme.cardTheme.color,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: theme.colorScheme.outline),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                      ),
                                      Text(
                                        '+${item.quantity} units @ ${CurrencyFormatter.formatPaise(item.unitPricePaise)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.formatPaise(item.subtotalPaise),
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                                  onPressed: () => setState(() => _items.removeAt(index)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 20),

                    // Payment Status & Notes
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _paymentStatus,
                            decoration: const InputDecoration(labelText: 'Payment Status'),
                            items: const [
                              DropdownMenuItem(value: 'PAID', child: Text('PAID (Cash/Bank)')),
                              DropdownMenuItem(value: 'PENDING', child: Text('PENDING (Supplier Credit)')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _paymentStatus = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                        prefixIcon: Icon(Icons.note_alt_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Inward Total & Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Inward Value',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      Text(
                        CurrencyFormatter.formatPaise(_totalPaise),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _confirmPurchase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Confirm & Inward Stock'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

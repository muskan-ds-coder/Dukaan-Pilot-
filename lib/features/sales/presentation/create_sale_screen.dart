import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/sale.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../inventory/presentation/inventory_screen.dart';
import 'sales_screen.dart';

class CreateSaleScreen extends ConsumerStatefulWidget {
  const CreateSaleScreen({super.key});

  @override
  ConsumerState<CreateSaleScreen> createState() => _CreateSaleScreenState();
}

class _CreateSaleScreenState extends ConsumerState<CreateSaleScreen> {
  final List<SaleItem> _cartItems = [];
  Customer? _selectedCustomer;
  String _selectedPaymentMethod = 'Cash';
  final _discountController = TextEditingController(text: '0');
  final _receivedAmountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _discountController.dispose();
    _receivedAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _subtotalPaise {
    int sum = 0;
    for (final item in _cartItems) {
      sum += item.subtotalPaise;
    }
    return sum;
  }

  int get _discountPaise {
    return CurrencyFormatter.parseToPaise(_discountController.text);
  }

  int get _totalPaise {
    final t = _subtotalPaise - _discountPaise;
    return t > 0 ? t : 0;
  }

  int get _receivedAmountPaise {
    if (_selectedPaymentMethod != 'Split Payment') {
      return _totalPaise;
    }
    return CurrencyFormatter.parseToPaise(_receivedAmountController.text);
  }

  int get _splitUdhaarDuePaise {
    final due = _totalPaise - _receivedAmountPaise;
    return due > 0 ? due : 0;
  }

  void _openProductPicker() async {
    final repo = ref.read(productRepositoryProvider);
    final allProducts = await repo.getProducts();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          String searchQuery = '';
          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            expand: false,
            builder: (_, scrollController) {
              final filtered = allProducts.where((p) {
                if (searchQuery.isEmpty) return true;
                final q = searchQuery.toLowerCase();
                return p.name.toLowerCase().contains(q) ||
                    (p.barcode != null && p.barcode!.toLowerCase().contains(q)) ||
                    (p.category != null && p.category!.toLowerCase().contains(q));
              }).toList();

              return Column(
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add Products to Bill',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                        ),
                        IconButton(
                          icon: const Icon(Icons.qr_code_scanner_rounded),
                          tooltip: 'Simulate Barcode Scan',
                          onPressed: () {
                            if (allProducts.isNotEmpty) {
                              final p = allProducts.first;
                              Navigator.pop(ctx);
                              _addProductToCart(p);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Scanned barcode for "${p.name}"'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search product or barcode...',
                        prefixIcon: const Icon(Icons.search),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          searchQuery = val;
                        });
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: filtered.isEmpty
                      ? const Center(child: Text('No matching products found.'))
                      : ListView.separated(
                          controller: scrollController,
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (_, index) {
                            final p = filtered[index];
                            final isOutOfStock = p.stockQuantity <= 0;
                            return ListTile(
                              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                'Stock: ${p.stockQuantity} ${p.unit} • ${p.category ?? ""}',
                                style: TextStyle(
                                  color: isOutOfStock ? Colors.red : Colors.grey.shade600,
                                ),
                              ),
                              trailing: Text(
                                CurrencyFormatter.formatPaise(p.sellingPricePaise),
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                              enabled: !isOutOfStock,
                              onTap: () {
                                Navigator.pop(ctx);
                                _addProductToCart(p);
                              },
                            );
                          },
                        ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _addProductToCart(Product p) {
    final existingIndex = _cartItems.indexWhere((i) => i.productId == p.id);
    if (existingIndex >= 0) {
      final existing = _cartItems[existingIndex];
      if (existing.quantity + 1 > p.stockQuantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot add more than available stock (${p.stockQuantity}).')),
        );
        return;
      }
      setState(() {
        final newQty = existing.quantity + 1;
        _cartItems[existingIndex] = existing.copyWith(
          quantity: newQty,
          subtotalPaise: newQty * existing.unitPricePaise,
        );
      });
    } else {
      setState(() {
        _cartItems.add(
          SaleItem(
            id: '',
            saleId: '',
            productId: p.id,
            productName: p.name,
            quantity: 1,
            unitPricePaise: p.sellingPricePaise,
            subtotalPaise: p.sellingPricePaise,
          ),
        );
      });
    }
  }

  void _openCustomerPicker() async {
    final repo = ref.read(customerRepositoryProvider);
    final customers = await repo.getCustomers();

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
                    'Select Customer',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showQuickAddCustomerDialog();
                    },
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('New'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.person_outline),
              ),
              title: const Text('Walk-in Customer'),
              subtitle: const Text('No credit / udhaar linked'),
              selected: _selectedCustomer == null,
              onTap: () {
                setState(() => _selectedCustomer = null);
                Navigator.pop(ctx);
              },
            ),
            ...customers.map((c) => ListTile(
                  leading: CircleAvatar(
                    child: Text(c.name.substring(0, 1).toUpperCase()),
                  ),
                  title: Text(c.name),
                  subtitle: Text(
                    c.currentBalancePaise > 0
                        ? 'Udhaar Due: ${CurrencyFormatter.formatPaise(c.currentBalancePaise)}'
                        : 'Balance: ₹0',
                    style: TextStyle(
                      color: c.currentBalancePaise > 0 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  selected: _selectedCustomer?.id == c.id,
                  onTap: () {
                    setState(() => _selectedCustomer = c);
                    Navigator.pop(ctx);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showQuickAddCustomerDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quick Add Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Customer Name *'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Mobile Phone'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final repo = ref.read(customerRepositoryProvider);
              final newCust = await repo.addCustomer(
                Customer(
                  id: '',
                  businessId: '',
                  name: name,
                  phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                  openingBalancePaise: 0,
                  currentBalancePaise: 0,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              );
              setState(() => _selectedCustomer = newCust);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save & Select'),
          ),
        ],
      ),
    );
  }

  void _confirmSale() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product to the sale cart.')),
      );
      return;
    }

    // Customer validation for credit
    if ((_selectedPaymentMethod == 'Credit/Udhaar' || _selectedPaymentMethod == 'Split Payment') &&
        _selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or add a Customer for Credit / Split transactions.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      _openCustomerPicker();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final saleRepo = ref.read(saleRepositoryProvider);

      int? receivedPaise;
      int? udhaarPaise;

      if (_selectedPaymentMethod == 'Split Payment') {
        receivedPaise = _receivedAmountPaise;
        udhaarPaise = _splitUdhaarDuePaise;
      } else if (_selectedPaymentMethod == 'Credit/Udhaar') {
        receivedPaise = 0;
        udhaarPaise = _totalPaise;
      } else {
        receivedPaise = _totalPaise;
        udhaarPaise = 0;
      }

      final createdSale = await saleRepo.createSale(
        customerId: _selectedCustomer?.id,
        items: _cartItems,
        discountPaise: _discountPaise,
        paymentMethod: _selectedPaymentMethod,
        receivedAmountPaise: receivedPaise,
        udhaarAmountPaise: udhaarPaise,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      // Invalidate relevant providers to immediately update UI
      ref.invalidate(salesListProvider);
      ref.invalidate(inventoryProductsProvider);
      ref.invalidate(todaySalesTotalProvider);
      ref.invalidate(todayTransactionsProvider);
      ref.invalidate(todayNetCashProvider);
      ref.invalidate(lowStockCountProvider);
      ref.invalidate(totalUdhaarProvider);

      if (!mounted) return;

      _showSaleCompletedDialog(createdSale);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete sale: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSaleCompletedDialog(Sale sale) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sale Completed!',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
            ),
            const SizedBox(height: 6),
            Text(
              'Total: ${CurrencyFormatter.formatPaise(sale.totalPaise)} (${sale.paymentMethod})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.pushReplacement('/sales/${sale.id}');
                    },
                    icon: const Icon(Icons.receipt_long_rounded),
                    label: const Text('View Bill'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _cartItems.clear();
                        _selectedCustomer = null;
                        _discountController.text = '0';
                        _receivedAmountController.clear();
                        _notesController.clear();
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Next Sale'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sale POS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Barcode Scanner',
            onPressed: _openProductPicker,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Customer Selector Card
                    InkWell(
                      onTap: _openCustomerPicker,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.colorScheme.outline),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                              child: Icon(
                                _selectedCustomer != null ? Icons.person : Icons.person_outline,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedCustomer?.name ?? 'Walk-in Customer',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                  ),
                                  Text(
                                    _selectedCustomer != null
                                        ? (_selectedCustomer!.phone ?? 'Customer linked')
                                        : 'Tap to select customer for Udhaar/Khata',
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

                    // Cart Header & Add Product Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Items Cart (${_cartItems.length})',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        TextButton.icon(
                          onPressed: _openProductPicker,
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          label: const Text('Add Items'),
                        ),
                      ],
                    ),

                    // Empty or List of Cart Items
                    if (_cartItems.isEmpty)
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
                              Icons.shopping_cart_outlined,
                              size: 48,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Cart is empty',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap "Add Items" or scan barcode to add products',
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
                        itemCount: _cartItems.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _cartItems[index];
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
                                        'Rate: ${CurrencyFormatter.formatPaise(item.unitPricePaise)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 22),
                                      onPressed: () {
                                        setState(() {
                                          if (item.quantity > 1) {
                                            final newQty = item.quantity - 1;
                                            _cartItems[index] = item.copyWith(
                                              quantity: newQty,
                                              subtotalPaise: newQty * item.unitPricePaise,
                                            );
                                          } else {
                                            _cartItems.removeAt(index);
                                          }
                                        });
                                      },
                                    ),
                                    Text(
                                      '${item.quantity}',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, size: 22),
                                      onPressed: () {
                                        setState(() {
                                          final newQty = item.quantity + 1;
                                          _cartItems[index] = item.copyWith(
                                            quantity: newQty,
                                            subtotalPaise: newQty * item.unitPricePaise,
                                          );
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  CurrencyFormatter.formatPaise(item.subtotalPaise),
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 20),

                    // Payment Method Selector
                    Text(
                      'Payment Method',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: AppConstants.paymentMethods.map((m) {
                        final isSelected = _selectedPaymentMethod == m;
                        return ChoiceChip(
                          label: Text(m),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setState(() => _selectedPaymentMethod = m);
                          },
                        );
                      }).toList(),
                    ),

                    // Split Payment Extra Fields
                    if (_selectedPaymentMethod == 'Split Payment') ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEA580C).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFEA580C).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Split Payment Calculation',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFFC2410C)),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _receivedAmountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Received in Cash / UPI (₹) *',
                                prefixIcon: Icon(Icons.payments_outlined),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Balance to add as Customer Udhaar:'),
                                Text(
                                  CurrencyFormatter.formatPaise(_splitUdhaarDuePaise),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Discount & Notes
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _discountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Discount (₹)',
                              prefixIcon: Icon(Icons.discount_outlined),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _notesController,
                            decoration: const InputDecoration(
                              labelText: 'Notes (Optional)',
                              prefixIcon: Icon(Icons.note_alt_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Total & Confirm Button
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
                        'Total Payable',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      Text(
                        CurrencyFormatter.formatPaise(_totalPaise),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _confirmSale,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Confirm & Complete Sale'),
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

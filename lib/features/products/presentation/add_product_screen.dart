import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/product.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../inventory/presentation/inventory_screen.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _categoryController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _stockQuantityController = TextEditingController(text: '0');
  final _minimumStockController = TextEditingController(text: '5');
  final _barcodeController = TextEditingController();
  String _selectedUnit = 'Piece';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _categoryController.dispose();
    _sellingPriceController.dispose();
    _purchasePriceController.dispose();
    _stockQuantityController.dispose();
    _minimumStockController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final sellingPricePaise = CurrencyFormatter.parseToPaise(_sellingPriceController.text);
      final purchasePricePaise = CurrencyFormatter.parseToPaise(_purchasePriceController.text);
      final stockQty = int.tryParse(_stockQuantityController.text.trim()) ?? 0;
      final minStock = int.tryParse(_minimumStockController.text.trim()) ?? 5;

      final repo = ref.read(productRepositoryProvider);
      await repo.addProduct(
        Product(
          id: '',
          businessId: '',
          name: _nameController.text.trim(),
          brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
          category: _categoryController.text.trim().isEmpty ? 'General' : _categoryController.text.trim(),
          sellingPricePaise: sellingPricePaise,
          purchasePricePaise: purchasePricePaise,
          stockQuantity: stockQty,
          minimumStock: minStock,
          unit: _selectedUnit,
          barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      ref.invalidate(productsListProvider);
      ref.invalidate(dashboardMetricsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding product: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Product'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Product Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name *',
                    hintText: 'e.g. Lakme Peach Milk Moisturizer',
                    prefixIcon: Icon(Icons.shopping_bag_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter product name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Brand & Category Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _brandController,
                        decoration: const InputDecoration(
                          labelText: 'Brand',
                          hintText: 'e.g. Lakme',
                          prefixIcon: Icon(Icons.branding_watermark_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          hintText: 'e.g. Cosmetics',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Selling Price & Purchase Price Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _sellingPriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Selling Price (₹) *',
                          prefixIcon: Icon(Icons.currency_rupee),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Enter price';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _purchasePriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Cost Price (₹)',
                          prefixIcon: Icon(Icons.currency_rupee),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Initial Stock & Unit Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stockQuantityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Initial Stock Qty',
                          prefixIcon: Icon(Icons.numbers),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedUnit,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          prefixIcon: Icon(Icons.straighten_outlined),
                        ),
                        items: AppConstants.productUnits.map((u) {
                          return DropdownMenuItem(value: u, child: Text(u));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedUnit = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Minimum Stock (Low stock alert threshold)
                TextFormField(
                  controller: _minimumStockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Low Stock Alert Threshold',
                    hintText: 'Default: 5',
                    prefixIcon: Icon(Icons.warning_amber_rounded),
                    helperText: 'Alerts you when inventory falls to or below this level',
                  ),
                ),
                const SizedBox(height: 16),

                // Barcode
                TextFormField(
                  controller: _barcodeController,
                  decoration: const InputDecoration(
                    labelText: 'Barcode / SKU (Optional)',
                    prefixIcon: Icon(Icons.qr_code_scanner_outlined),
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Save Product'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

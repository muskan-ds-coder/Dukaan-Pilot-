import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/product.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../inventory/presentation/inventory_screen.dart';
import 'product_detail_screen.dart';

class EditProductScreen extends ConsumerStatefulWidget {
  final String productId;

  const EditProductScreen({super.key, required this.productId});

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _categoryController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _minimumStockController = TextEditingController();
  final _barcodeController = TextEditingController();
  String _selectedUnit = 'Piece';
  bool _isLoading = false;
  bool _isInitialized = false;
  Product? _existingProduct;

  @override
  void initState() {
    super.initState();
    _loadProductData();
  }

  Future<void> _loadProductData() async {
    final repo = ref.read(productRepositoryProvider);
    final p = await repo.getProductById(widget.productId);
    if (p != null && mounted) {
      setState(() {
        _existingProduct = p;
        _nameController.text = p.name;
        _brandController.text = p.brand ?? '';
        _categoryController.text = p.category ?? '';
        _sellingPriceController.text = CurrencyFormatter.paiseToRupees(p.sellingPricePaise).toString();
        _purchasePriceController.text = CurrencyFormatter.paiseToRupees(p.purchasePricePaise).toString();
        _minimumStockController.text = p.minimumStock.toString();
        _barcodeController.text = p.barcode ?? '';
        _selectedUnit = AppConstants.productUnits.contains(p.unit) ? p.unit : 'Piece';
        _isInitialized = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _categoryController.dispose();
    _sellingPriceController.dispose();
    _purchasePriceController.dispose();
    _minimumStockController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate() || _existingProduct == null) return;

    setState(() => _isLoading = true);
    try {
      final sellingPricePaise = CurrencyFormatter.parseToPaise(_sellingPriceController.text);
      final purchasePricePaise = CurrencyFormatter.parseToPaise(_purchasePriceController.text);
      final minStock = int.tryParse(_minimumStockController.text.trim()) ?? 5;

      final updated = _existingProduct!.copyWith(
        name: _nameController.text.trim(),
        brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
        category: _categoryController.text.trim().isEmpty ? 'General' : _categoryController.text.trim(),
        sellingPricePaise: sellingPricePaise,
        purchasePricePaise: purchasePricePaise,
        minimumStock: minStock,
        unit: _selectedUnit,
        barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
        updatedAt: DateTime.now(),
      );

      final repo = ref.read(productRepositoryProvider);
      await repo.updateProduct(updated);

      ref.invalidate(productDetailProvider(widget.productId));
      ref.invalidate(productsListProvider);
      ref.invalidate(dashboardMetricsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating product: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Product')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product Details'),
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
                    prefixIcon: Icon(Icons.shopping_bag_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Product name cannot be empty';
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
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Selling Price & Cost Price
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
                          if (val == null || val.trim().isEmpty) return 'Enter price';
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

                // Unit & Min Stock
                Row(
                  children: [
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _minimumStockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Min Stock Alert',
                          prefixIcon: Icon(Icons.warning_amber_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Barcode / SKU
                TextFormField(
                  controller: _barcodeController,
                  decoration: InputDecoration(
                    labelText: 'Barcode / SKU',
                    prefixIcon: const Icon(Icons.qr_code_scanner_outlined),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.camera_alt_outlined),
                      tooltip: 'Scan Barcode',
                      onPressed: () {
                        // Quick demo barcode generator for testing scanner
                        final sampleCode = '8901030${DateTime.now().millisecond}';
                        setState(() => _barcodeController.text = sampleCode);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Barcode detected: $sampleCode')),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Save Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

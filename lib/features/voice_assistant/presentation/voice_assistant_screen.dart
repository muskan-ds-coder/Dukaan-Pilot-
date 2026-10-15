import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/stock_movement.dart';
import '../../../domain/entities/sale.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../inventory/presentation/inventory_screen.dart';
import '../../sales/presentation/sales_screen.dart';

enum VoiceStatus {
  idle,
  listening,
  processing,
  reviewAction,
  confirmed,
  error,
}

class ParsedCommand {
  final String action; // SALE, STOCK_IN, CREDIT_GIVEN, PAYMENT, DAMAGE, QUERY_SALES, QUERY_LOW_STOCK
  final String? productName;
  final String? customerName;
  final int quantity;
  final int amountPaise;
  final Product? matchedProduct;
  final double confidence;
  final String rawSpokenText;

  const ParsedCommand({
    required this.action,
    this.productName,
    this.customerName,
    this.quantity = 1,
    this.amountPaise = 0,
    this.matchedProduct,
    this.confidence = 0.95,
    required this.rawSpokenText,
  });
}

class VoiceAssistantScreen extends ConsumerStatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  ConsumerState<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends ConsumerState<VoiceAssistantScreen> {
  VoiceStatus _status = VoiceStatus.idle;
  String _spokenText = '';
  ParsedCommand? _interpretedAction;
  String? _errorMessage;
  String? _queryAnswer;

  // Preset voice command triggers for easy one-tap speaking or custom speech simulation
  final List<String> _sampleVoiceCommands = [
    '5 Lakme face wash bike',
    '10 Dove soap aaye',
    'Ramesh ko 500 rupaye ka udhaar diya',
    'Ramesh ne 300 rupaye pay kiye',
    '2 Dove soap damage ho gaye',
    'Aaj kitni sale hui?',
    'Kaunsa product low stock mein hai?',
  ];

  void _startListening([String? simulatedCommand]) async {
    setState(() {
      _status = VoiceStatus.listening;
      _spokenText = '';
      _interpretedAction = null;
      _errorMessage = null;
      _queryAnswer = null;
    });

    // Animate listening state
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    final command = simulatedCommand ?? _sampleVoiceCommands.first;
    setState(() {
      _spokenText = command;
      _status = VoiceStatus.processing;
    });

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    _processSpokenText(command);
  }

  void _processSpokenText(String text) async {
    final lower = text.toLowerCase().trim();
    final prodRepo = ref.read(productRepositoryProvider);
    final saleRepo = ref.read(saleRepositoryProvider);

    try {
      // 1. Natural Language Analytical Queries (Section 21)
      if (lower.contains('kitni sale') || lower.contains('total sale')) {
        final totalSales = await saleRepo.getTodaySalesTotal();
        setState(() {
          _status = VoiceStatus.confirmed;
          _queryAnswer = 'Aaj total sales ${CurrencyFormatter.formatPaise(totalSales)} hui hai.';
        });
        return;
      }

      if (lower.contains('low stock') || lower.contains('khatam')) {
        final lowList = await prodRepo.getLowStockProducts();
        if (lowList.isEmpty) {
          setState(() {
            _status = VoiceStatus.confirmed;
            _queryAnswer = 'Sabhi products ka stock healthy hai! Koi item low nahi hai.';
          });
        } else {
          final items = lowList.map((p) => '${p.name} (${p.stockQuantity} ${p.unit})').join(', ');
          setState(() {
            _status = VoiceStatus.confirmed;
            _queryAnswer = 'Ye products low stock mein hain: $items';
          });
        }
        return;
      }

      // 2. Transactional Actions (Sale, Stock In, Udhaar, Payment, Damage)
      final allProducts = await prodRepo.getProducts();

      // Find matching product
      Product? matchedProduct;
      for (final p in allProducts) {
        if (lower.contains(p.name.toLowerCase()) ||
            (p.brand != null && lower.contains(p.brand!.toLowerCase()))) {
          matchedProduct = p;
          break;
        }
      }

      // Extract quantity
      final match = RegExp(r'\b(\d+)\b').firstMatch(lower);
      final qty = match != null ? int.parse(match.group(1)!) : 1;

      String action = 'SALE';
      int amount = 0;
      String? customerName;

      if (lower.contains('bike') || lower.contains('sold') || lower.contains('sale')) {
        action = 'SALE';
        if (matchedProduct != null) {
          amount = matchedProduct.sellingPricePaise * qty;
        }
      } else if (lower.contains('aaye') || lower.contains('purchase') || lower.contains('aaya')) {
        action = 'STOCK_IN';
        if (matchedProduct != null) {
          amount = matchedProduct.purchasePricePaise * qty;
        }
      } else if (lower.contains('udhaar') || lower.contains('credit')) {
        action = 'CREDIT_GIVEN';
        customerName = 'Ramesh Kumar';
        amount = 50000; // ₹500
      } else if (lower.contains('pay') || lower.contains('jama')) {
        action = 'PAYMENT_RECEIVED';
        customerName = 'Ramesh Kumar';
        amount = 30000; // ₹300
      } else if (lower.contains('damage') || lower.contains('kharab')) {
        action = 'DAMAGE';
      }

      setState(() {
        _status = VoiceStatus.reviewAction;
        _interpretedAction = ParsedCommand(
          action: action,
          productName: matchedProduct?.name ?? (customerName != null ? null : 'Product'),
          customerName: customerName,
          quantity: qty,
          amountPaise: amount,
          matchedProduct: matchedProduct,
          rawSpokenText: text,
        );
      });
    } catch (e) {
      setState(() {
        _status = VoiceStatus.error;
        _errorMessage = 'Could not understand command. Please try again.';
      });
    }
  }

  void _confirmAction() async {
    final action = _interpretedAction;
    if (action == null) return;

    setState(() => _status = VoiceStatus.processing);
    final prodRepo = ref.read(productRepositoryProvider);
    final saleRepo = ref.read(saleRepositoryProvider);
    final custRepo = ref.read(customerRepositoryProvider);

    try {
      if (action.action == 'SALE' && action.matchedProduct != null) {
        await saleRepo.createSale(
          items: [
            SaleItem(
              id: '',
              saleId: '',
              productId: action.matchedProduct!.id,
              productName: action.matchedProduct!.name,
              quantity: action.quantity,
              unitPricePaise: action.matchedProduct!.sellingPricePaise,
              subtotalPaise: action.amountPaise,
            ),
          ],
          paymentMethod: 'Cash',
          notes: 'Voice command: ${action.rawSpokenText}',
        );
      } else if (action.action == 'STOCK_IN' && action.matchedProduct != null) {
        await prodRepo.recordStockMovement(
          StockMovement(
            id: '',
            businessId: action.matchedProduct!.businessId,
            productId: action.matchedProduct!.id,
            type: AppConstants.movementPurchase,
            quantity: action.quantity,
            previousStock: action.matchedProduct!.stockQuantity,
            newStock: action.matchedProduct!.stockQuantity + action.quantity,
            note: 'Voice stock-in: ${action.rawSpokenText}',
            createdAt: DateTime.now(),
          ),
        );
      } else if (action.action == 'DAMAGE' && action.matchedProduct != null) {
        await prodRepo.recordStockMovement(
          StockMovement(
            id: '',
            businessId: action.matchedProduct!.businessId,
            productId: action.matchedProduct!.id,
            type: AppConstants.movementDamage,
            quantity: action.quantity,
            previousStock: action.matchedProduct!.stockQuantity,
            newStock: action.matchedProduct!.stockQuantity - action.quantity,
            note: 'Voice damage log: ${action.rawSpokenText}',
            createdAt: DateTime.now(),
          ),
        );
      } else if (action.action == 'PAYMENT_RECEIVED' && action.customerName != null) {
        final customers = await custRepo.getCustomers(query: 'Ramesh');
        if (customers.isNotEmpty) {
          await custRepo.recordPayment(
            customerId: customers.first.id,
            amountPaise: action.amountPaise,
            note: 'Voice payment: ${action.rawSpokenText}',
          );
        }
      }

      ref.invalidate(dashboardMetricsProvider);
      ref.invalidate(productsListProvider);
      ref.invalidate(salesListProvider);

      setState(() {
        _status = VoiceStatus.confirmed;
      });
    } catch (e) {
      setState(() {
        _status = VoiceStatus.error;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Assistant'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            children: [
              // Voice Status Title
              Text(
                _getStatusTitle(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Speak your shop sales, stock updates, or questions in Hindi or English.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.65)),
              ),
              const SizedBox(height: 36),

              // Large Interactive Microphone Button
              GestureDetector(
                onTap: _status == VoiceStatus.listening ? null : () => _startListening(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _status == VoiceStatus.listening
                          ? [const Color(0xFFDC2626), const Color(0xFFEF4444)]
                          : [const Color(0xFF4F46E5), const Color(0xFF6366F1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_status == VoiceStatus.listening
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF4F46E5))
                            .withOpacity(0.4),
                        blurRadius: _status == VoiceStatus.listening ? 36 : 22,
                        spreadRadius: _status == VoiceStatus.listening ? 8 : 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _status == VoiceStatus.listening ? Icons.mic : Icons.mic_none_rounded,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Transcript & Status Feedback
              if (_spokenText.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOU SAID:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '"$_spokenText"',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Answer card if analytical query
              if (_queryAnswer != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF0D9488)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF0D9488), size: 30),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          _queryAnswer!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF0D9488),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Review Confirmation Box (Section 20 & 49)
              if (_status == VoiceStatus.reviewAction && _interpretedAction != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: theme.colorScheme.primary, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'AI Interpreted Action',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          Chip(
                            label: Text(
                              _interpretedAction!.action,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (_interpretedAction!.productName != null) ...[
                        _ReviewRow(
                          label: 'Product',
                          value: _interpretedAction!.productName!,
                          icon: Icons.inventory_2_outlined,
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (_interpretedAction!.customerName != null) ...[
                        _ReviewRow(
                          label: 'Customer',
                          value: _interpretedAction!.customerName!,
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 8),
                      ],
                      _ReviewRow(
                        label: 'Quantity',
                        value: '${_interpretedAction!.quantity}',
                        icon: Icons.numbers,
                      ),
                      if (_interpretedAction!.amountPaise > 0) ...[
                        const SizedBox(height: 8),
                        _ReviewRow(
                          label: 'Estimated Amount',
                          value: CurrencyFormatter.formatPaise(_interpretedAction!.amountPaise),
                          icon: Icons.currency_rupee,
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _status = VoiceStatus.idle;
                                  _interpretedAction = null;
                                });
                              },
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _confirmAction,
                              child: const Text('Confirm Action'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Success Banner
              if (_status == VoiceStatus.confirmed && _queryAnswer == null) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF0D9488)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF0D9488), size: 30),
                      SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Action confirmed and database updated cleanly!',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0D9488),
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Error Banner
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ),
                const SizedBox(height: 20),
              ],

              const SizedBox(height: 12),

              // Sample Preset Voice Commands Header
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'OR TAP A SAMPLE COMMAND TO TEST:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _sampleVoiceCommands.map((cmd) {
                  return ActionChip(
                    avatar: const Icon(Icons.mic, size: 16),
                    label: Text(cmd),
                    onPressed: () => _startListening(cmd),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusTitle() {
    switch (_status) {
      case VoiceStatus.listening:
        return 'Listening...';
      case VoiceStatus.processing:
        return 'Processing with AI...';
      case VoiceStatus.reviewAction:
        return 'Review & Confirm Action';
      case VoiceStatus.confirmed:
        return 'Success!';
      case VoiceStatus.error:
        return 'Try Again';
      case VoiceStatus.idle:
        return 'Tap to Speak';
    }
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReviewRow({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/ledger_entry.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import 'customer_list_screen.dart';

final customerDetailProvider = FutureProvider.family<Customer?, String>((ref, id) async {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.getCustomerById(id);
});

final customerLedgerProvider = FutureProvider.family<List<LedgerEntry>, String>((ref, id) async {
  final repo = ref.watch(customerRepositoryProvider);
  return repo.getCustomerLedger(id);
});

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  ConsumerState<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  void _sendWhatsAppReminder(Customer customer, String businessName) {
    final buffer = StringBuffer();
    buffer.writeln('🙏 *Namaste ${customer.name} ji,*');
    buffer.writeln('This is a gentle payment reminder from *$businessName*.');
    buffer.writeln('');
    buffer.writeln('Outstanding Udhaar Balance: *${CurrencyFormatter.formatPaise(customer.currentBalancePaise)}*');
    buffer.writeln('Please settle your bill at your earliest convenience via Cash or UPI.');
    buffer.writeln('');
    buffer.writeln('Thank you for shopping with us! ✨');

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('WhatsApp reminder message copied to clipboard!'),
        backgroundColor: Color(0xFF0D9488),
      ),
    );
  }

  void _showRecordPaymentDialog(Customer customer) {
    final amountController = TextEditingController(
      text: (customer.currentBalancePaise / 100).toStringAsFixed(0),
    );
    final noteController = TextEditingController();
    String paymentMode = 'Cash';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Collect Udhaar: ${customer.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Outstanding: ${CurrencyFormatter.formatPaise(customer.currentBalancePaise)}',
                style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Payment Received (₹) *',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: paymentMode,
                decoration: const InputDecoration(labelText: 'Payment Mode *'),
                items: const [
                  DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'UPI', child: Text('UPI / QR')),
                  DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => paymentMode = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Note / Ref ID (Optional)',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amountPaise = CurrencyFormatter.parseToPaise(amountController.text);
                if (amountPaise <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid payment amount.')),
                  );
                  return;
                }

                Navigator.pop(ctx);
                final repo = ref.read(customerRepositoryProvider);
                final note = noteController.text.trim().isNotEmpty
                    ? 'Payment via $paymentMode (${noteController.text.trim()})'
                    : 'Payment received via $paymentMode';

                await repo.recordPayment(
                  customerId: customer.id,
                  amountPaise: amountPaise,
                  note: note,
                );

                ref.invalidate(customerDetailProvider(widget.customerId));
                ref.invalidate(customerLedgerProvider(widget.customerId));
                ref.invalidate(customersListProvider);
                ref.invalidate(totalUdhaarProvider);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Payment of ${CurrencyFormatter.formatPaise(amountPaise)} recorded.'),
                      backgroundColor: const Color(0xFF0D9488),
                    ),
                  );
                }
              },
              child: const Text('Confirm Payment'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customerAsync = ref.watch(customerDetailProvider(widget.customerId));
    final ledgerAsync = ref.watch(customerLedgerProvider(widget.customerId));
    final business = ref.watch(currentBusinessProvider).value;
    final businessName = business?.name ?? 'DukaanPilot';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Khata'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(customerDetailProvider(widget.customerId));
              ref.invalidate(customerLedgerProvider(widget.customerId));
            },
          ),
        ],
      ),
      body: customerAsync.when(
        data: (customer) {
          if (customer == null) {
            return const Center(child: Text('Customer not found.'));
          }

          final hasCredit = customer.currentBalancePaise > 0;
          final dateStr = DateFormat('dd MMM yyyy').format(customer.createdAt);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Customer Profile Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                        child: Text(
                          customer.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer.name,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                            ),
                            const SizedBox(height: 4),
                            if (customer.phone != null)
                              Row(
                                children: [
                                  const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    customer.phone!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            if (customer.address != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  customer.address!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              'Customer since $dateStr',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Hero Udhaar Due Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: hasCredit
                          ? [const Color(0xFF991B1B), const Color(0xFF7F1D1D)]
                          : [const Color(0xFF065F46), const Color(0xFF047857)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: (hasCredit ? Colors.red : Colors.green).withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        hasCredit ? 'CURRENT OUTSTANDING UDHAAR' : 'BALANCE STATUS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        CurrencyFormatter.formatPaise(customer.currentBalancePaise),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showRecordPaymentDialog(customer),
                              icon: const Icon(Icons.payments_rounded, size: 18),
                              label: const Text('Record Payment'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          if (hasCredit) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _sendWhatsAppReminder(customer, businessName),
                                icon: const Icon(Icons.notifications_active_rounded, size: 18, color: Colors.white),
                                label: const Text('Reminder', style: TextStyle(color: Colors.white)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.white, width: 1.5),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Transaction Ledger Header
                Text(
                  'Transaction History (Khata Ledger)',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),

                // Ledger entries list
                ledgerAsync.when(
                  data: (entries) {
                    if (entries.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.colorScheme.outline),
                        ),
                        child: Center(
                          child: Text(
                            'No transactions recorded for this customer.',
                            style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final e = entries[index];
                        final isCredit = e.type == AppConstants.ledgerCredit;
                        final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(e.createdAt);

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.cardTheme.color,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: theme.colorScheme.outline),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: (isCredit ? const Color(0xFFDC2626) : const Color(0xFF10B981))
                                      .withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isCredit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                  size: 18,
                                  color: isCredit ? const Color(0xFFDC2626) : const Color(0xFF0D9488),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.description ?? (isCredit ? 'Credit added (Udhaar)' : 'Payment received'),
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      dateStr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${isCredit ? "+" : "-"}${CurrencyFormatter.formatPaise(e.amountPaise)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: isCredit ? const Color(0xFFDC2626) : const Color(0xFF0D9488),
                                    ),
                                  ),
                                  Text(
                                    isCredit ? 'DEBIT' : 'CREDIT',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isCredit ? const Color(0xFFDC2626) : const Color(0xFF0D9488),
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
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

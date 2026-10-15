import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/customer.dart';
import '../../dashboard/providers/dashboard_provider.dart';

final customerSearchQueryProvider = StateProvider<String>((ref) => '');

final customersListProvider = FutureProvider.autoDispose<List<Customer>>((ref) async {
  final query = ref.watch(customerSearchQueryProvider);
  final repo = ref.watch(customerRepositoryProvider);
  return repo.getCustomers(query: query.isEmpty ? null : query);
});

class CustomerListScreen extends ConsumerWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final customersAsync = ref.watch(customersListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers & Udhaar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(customersListProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-customer'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Customer', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search customer by name or phone...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: ref.watch(customerSearchQueryProvider).isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => ref.read(customerSearchQueryProvider.notifier).state = '',
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) {
                ref.read(customerSearchQueryProvider.notifier).state = val;
              },
            ),
          ),
          const Divider(height: 1),

          // Customer List
          Expanded(
            child: customersAsync.when(
              data: (customers) {
                if (customers.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 64,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No customers added yet',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add customer contacts to track Udhaar (credit) and payment receipts.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/add-customer'),
                            icon: const Icon(Icons.person_add_rounded),
                            label: const Text('Add First Customer'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                  itemCount: customers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    final hasCredit = customer.currentBalancePaise > 0;

                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => context.push('/customers/${customer.id}'),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.colorScheme.outline),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                                  child: Text(
                                    customer.name.substring(0, 1).toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        customer.name,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                      ),
                                      Text(
                                        customer.phone ?? customer.address ?? 'No contact info',
                                        style: TextStyle(
                                          fontSize: 12.5,
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
                                      hasCredit ? 'Udhaar Due' : 'All Clear',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: hasCredit ? const Color(0xFFDC2626) : const Color(0xFF0D9488),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.formatPaise(customer.currentBalancePaise),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: hasCredit ? const Color(0xFFDC2626) : const Color(0xFF0D9488),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => context.push('/customers/${customer.id}'),
                                  icon: const Icon(Icons.menu_book_rounded, size: 18),
                                  label: const Text('View Khata'),
                                ),
                                const SizedBox(width: 8),
                                if (hasCredit)
                                  ElevatedButton.icon(
                                    onPressed: () => _showQuickPaymentDialog(context, ref, customer),
                                    icon: const Icon(Icons.payment_rounded, size: 18),
                                    label: const Text('Record Payment'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0D9488),
                                      minimumSize: const Size(130, 40),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickPaymentDialog(BuildContext context, WidgetRef ref, Customer customer) {
    final amountController = TextEditingController(
      text: (customer.currentBalancePaise / 100).toStringAsFixed(0),
    );
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Collect Payment: ${customer.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Balance: ${CurrencyFormatter.formatPaise(customer.currentBalancePaise)}',
              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Amount Received (₹) *',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Note (Optional)',
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
                  const SnackBar(content: Text('Please enter a valid amount.')),
                );
                return;
              }

              Navigator.pop(ctx);
              final repo = ref.read(customerRepositoryProvider);
              await repo.recordPayment(
                customerId: customer.id,
                amountPaise: amountPaise,
                note: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
              );

              ref.invalidate(customersListProvider);
              ref.invalidate(totalUdhaarProvider);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Payment of ${CurrencyFormatter.formatPaise(amountPaise)} recorded.'),
                    backgroundColor: const Color(0xFF0D9488),
                  ),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

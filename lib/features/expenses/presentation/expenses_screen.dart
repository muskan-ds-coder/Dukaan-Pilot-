import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/expense.dart';

final selectedExpenseCategoryFilterProvider = StateProvider<String>((ref) => 'ALL');

final expensesListProvider = FutureProvider.autoDispose<List<Expense>>((ref) async {
  final repo = ref.watch(expenseRepositoryProvider);
  final cat = ref.watch(selectedExpenseCategoryFilterProvider);
  return repo.getExpenses(category: cat == 'ALL' ? null : cat);
});

final totalExpensesSummaryProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(expenseRepositoryProvider);
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  return repo.getTotalExpensesPaise(startDate: startOfMonth);
});

final categoryBreakdownProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final repo = ref.watch(expenseRepositoryProvider);
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);
  return repo.getExpensesByCategory(startDate: startOfMonth);
});

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Rent':
        return Icons.store_outlined;
      case 'Electricity':
        return Icons.bolt_outlined;
      case 'Transport':
        return Icons.local_shipping_outlined;
      case 'Salary':
        return Icons.badge_outlined;
      case 'Packaging':
        return Icons.inventory_2_outlined;
      case 'Supplier':
        return Icons.receipt_long_outlined;
      case 'Marketing':
        return Icons.campaign_outlined;
      case 'Other':
      default:
        return Icons.receipt_outlined;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Rent':
        return const Color(0xFF6366F1);
      case 'Electricity':
        return const Color(0xFFF59E0B);
      case 'Transport':
        return const Color(0xFF3B82F6);
      case 'Salary':
        return const Color(0xFF10B981);
      case 'Packaging':
        return const Color(0xFF8B5CF6);
      case 'Supplier':
        return const Color(0xFFEC4899);
      case 'Marketing':
        return const Color(0xFF14B8A6);
      case 'Other':
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final expensesAsync = ref.watch(expensesListProvider);
    final totalMonthlyAsync = ref.watch(totalExpensesSummaryProvider);
    final selectedCat = ref.watch(selectedExpenseCategoryFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses & Cash-Out'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(expensesListProvider);
              ref.invalidate(totalExpensesSummaryProvider);
              ref.invalidate(categoryBreakdownProvider);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-expense'),
        backgroundColor: const Color(0xFFDC2626),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.remove_circle_outline),
        label: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // Header Total Expenses Card
          totalMonthlyAsync.when(
            data: (totalPaise) {
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF991B1B), Color(0xFF7F1D1D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF991B1B).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOTAL EXPENSES THIS MONTH',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.formatPaise(totalPaise),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.trending_down_rounded, color: Colors.white, size: 28),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          // Horizontal Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: const Text('ALL'),
                    selected: selectedCat == 'ALL',
                    onSelected: (_) => ref.read(selectedExpenseCategoryFilterProvider.notifier).state = 'ALL',
                  ),
                ),
                ...AppConstants.expenseCategories.map((c) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(c),
                      selected: selectedCat == c,
                      onSelected: (_) => ref.read(selectedExpenseCategoryFilterProvider.notifier).state = c,
                    ),
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 1),

          // Expense List
          Expanded(
            child: expensesAsync.when(
              data: (expenses) {
                if (expenses.isEmpty) {
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
                            selectedCat == 'ALL'
                                ? 'No expenses recorded yet'
                                : 'No expenses in category "$selectedCat"',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Track rent, electricity, wages, tea/snacks, and maintenance to calculate true net profit.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/add-expense'),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Expense'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                  itemCount: expenses.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final exp = expenses[index];
                    final dateStr = DateFormat('dd MMM yyyy').format(exp.date);
                    final icon = _getCategoryIcon(exp.category);
                    final color = _getCategoryColor(exp.category);

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.colorScheme.outline),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, color: color, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exp.category,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                                if (exp.description != null && exp.description!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: Text(
                                      exp.description!,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 2),
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '-${CurrencyFormatter.formatPaise(exp.amountPaise)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Color(0xFFDC2626),
                            ),
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
          ),
        ],
      ),
    );
  }
}

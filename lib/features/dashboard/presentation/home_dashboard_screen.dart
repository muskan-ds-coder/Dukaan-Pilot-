import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final metricsAsync = ref.watch(dashboardMetricsProvider);

    final ownerName = authState.business?.ownerName ?? authState.user?.displayName ?? 'Shop Owner';
    final businessName = authState.business?.name ?? 'My Dukaan';
    final todayFormatted = DateFormat('EEEE, d MMMM y').format(DateTime.now());

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${_getGreeting()}, $ownerName 👋',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Text(
              '$businessName • $todayFormatted',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.65),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Business Reports & Analytics',
            onPressed: () => context.push('/reports'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Metrics',
            onPressed: () => ref.invalidate(dashboardMetricsProvider),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/voice-assistant'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.mic_rounded, size: 28),
        label: const Text(
          'Speak Command',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardMetricsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Real-Time Business Snapshot Cards
              metricsAsync.when(
                data: (metrics) {
                  return Column(
                    children: [
                      // Top Row: Sales & Purchases
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              title: "Today's Sales",
                              value: CurrencyFormatter.formatPaise(metrics.todaySalesPaise),
                              icon: Icons.trending_up_rounded,
                              color: const Color(0xFF0D9488), // Teal
                              subtitle: '${metrics.todayTransactionCount} sales today',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricCard(
                              title: "Today's Purchases",
                              value: CurrencyFormatter.formatPaise(metrics.todayPurchasesPaise),
                              icon: Icons.shopping_bag_outlined,
                              color: const Color(0xFF4F46E5), // Indigo
                              subtitle: 'Inward stock',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Second Row: Outstanding Udhaar & Low Stock
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              title: 'Outstanding Udhaar',
                              value: CurrencyFormatter.formatPaise(metrics.outstandingUdhaarPaise),
                              icon: Icons.account_balance_wallet_outlined,
                              color: const Color(0xFFDC2626), // Red
                              subtitle: 'Customer balance',
                              onTap: () => context.go('/customers'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricCard(
                              title: 'Low Stock Alerts',
                              value: '${metrics.lowStockCount}',
                              icon: Icons.warning_amber_rounded,
                              color: metrics.lowStockCount > 0
                                  ? const Color(0xFFF97316)
                                  : const Color(0xFF64748B),
                              subtitle: metrics.lowStockCount > 0 ? 'Need reorder' : 'All healthy',
                              onTap: () => context.push('/low-stock'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Third Row: Today Expenses
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              title: "Today's Expenses",
                              value: CurrencyFormatter.formatPaise(metrics.todayExpensesPaise),
                              icon: Icons.receipt_long_outlined,
                              color: const Color(0xFF6366F1),
                              subtitle: 'Shop overheads',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricCard(
                              title: 'Transactions',
                              value: '${metrics.todayTransactionCount}',
                              icon: Icons.receipt_outlined,
                              color: const Color(0xFF0F172A),
                              subtitle: "Today's activity",
                            ),
                          ),
                        ],
                      ),

                      if (!metrics.hasAnyData) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.lightbulb_outline, color: theme.colorScheme.primary, size: 32),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Start by adding your first product',
                                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Add your cosmetic or kirana items to begin logging sales and voice commands.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text('Error loading dashboard: $err'),
                ),
              ),

              const SizedBox(height: 28),

              // Quick Actions Header
              Text(
                'Quick Actions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 14),

              // Quick Actions Grid
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.82,
                children: [
                  _QuickActionButton(
                    icon: Icons.point_of_sale_rounded,
                    label: '+ Sale',
                    color: const Color(0xFF0D9488),
                    onTap: () => context.push('/create-sale'),
                  ),
                  _QuickActionButton(
                    icon: Icons.shopping_bag_rounded,
                    label: 'Inward Bill',
                    color: const Color(0xFF0F766E),
                    onTap: () => context.push('/create-purchase'),
                  ),
                  _QuickActionButton(
                    icon: Icons.remove_circle_outline_rounded,
                    label: '+ Expense',
                    color: const Color(0xFFDC2626),
                    onTap: () => context.push('/add-expense'),
                  ),
                  _QuickActionButton(
                    icon: Icons.menu_book_rounded,
                    label: 'Khata Due',
                    color: const Color(0xFFB91C1C),
                    onTap: () => context.push('/customers'),
                  ),
                  _QuickActionButton(
                    icon: Icons.add_box_rounded,
                    label: '+ Product',
                    color: const Color(0xFF4F46E5),
                    onTap: () => context.push('/add-product'),
                  ),
                  _QuickActionButton(
                    icon: Icons.history_edu_rounded,
                    label: 'Stock Audit',
                    color: const Color(0xFF6366F1),
                    onTap: () => context.push('/stock-movements'),
                  ),
                  _QuickActionButton(
                    icon: Icons.people_outline_rounded,
                    label: 'Suppliers',
                    color: const Color(0xFF2563EB),
                    onTap: () => context.push('/suppliers'),
                  ),
                  _QuickActionButton(
                    icon: Icons.document_scanner_rounded,
                    label: 'Scan Bill',
                    color: const Color(0xFFEA580C),
                    onTap: () => context.push('/invoice-scanner'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Voice Assistant Highlight Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF312E81).withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mic_none_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Try Voice Command',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Say "5 Dove soap bike" or "Ramesh ko 500 ka udhaar"',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 18),
                      onPressed: () => context.push('/voice-assistant'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withOpacity(0.65),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Icon(icon, color: color, size: 26),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

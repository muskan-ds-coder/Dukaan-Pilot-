import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../providers/reports_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  void _shareReportSummary(
    BuildContext context,
    ReportsData data,
    String businessName,
    ReportTimeRange range,
  ) {
    String rangeLabel;
    switch (range) {
      case ReportTimeRange.today:
        rangeLabel = "Today's Briefing";
        break;
      case ReportTimeRange.last7Days:
        rangeLabel = 'Last 7 Days Performance';
        break;
      case ReportTimeRange.last30Days:
        rangeLabel = 'Last 30 Days Summary';
        break;
      case ReportTimeRange.allTime:
        rangeLabel = 'All-Time Performance';
        break;
    }

    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final buffer = StringBuffer();
    buffer.writeln('📊 *BUSINESS REPORT: ${businessName.toUpperCase()}*');
    buffer.writeln('📅 Period: $rangeLabel ($dateStr)');
    buffer.writeln('--------------------------------');
    buffer.writeln('💰 *Total Gross Sales:* ${CurrencyFormatter.formatPaise(data.totalSalesPaise)}');
    buffer.writeln('🧾 *Transactions:* ${data.totalTransactions}');
    buffer.writeln('📦 *Inward Purchases:* ${CurrencyFormatter.formatPaise(data.totalPurchasesPaise)}');
    buffer.writeln('📉 *Store Expenses:* ${CurrencyFormatter.formatPaise(data.totalExpensesPaise)}');
    buffer.writeln('✨ *Net Profit:* ${CurrencyFormatter.formatPaise(data.netProfitPaise)}');
    buffer.writeln('🔴 *Outstanding Udhaar:* ${CurrencyFormatter.formatPaise(data.outstandingUdhaarPaise)}');
    buffer.writeln('--------------------------------');

    if (data.topProducts.isNotEmpty) {
      buffer.writeln('🏆 *Top Selling Products:*');
      for (int i = 0; i < data.topProducts.length; i++) {
        final p = data.topProducts[i];
        buffer.writeln('${i + 1}. ${p.productName}: ${p.unitsSold} units (${CurrencyFormatter.formatPaise(p.totalRevenuePaise)})');
      }
      buffer.writeln('--------------------------------');
    }

    buffer.writeln('_Generated via DukaanPilot AI_ 🚀');

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report summary copied! Ready to share on WhatsApp.'),
        backgroundColor: Color(0xFF0D9488),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedRange = ref.watch(selectedReportTimeRangeProvider);
    final reportAsync = ref.watch(reportsDataProvider);
    final business = ref.watch(currentBusinessProvider).value;
    final businessName = business?.name ?? 'My Dukaan';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Business Analytics & Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Analytics',
            onPressed: () => ref.invalidate(reportsDataProvider),
          ),
          reportAsync.when(
            data: (data) => IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Share Report',
              onPressed: () => _shareReportSummary(context, data, businessName, selectedRange),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Time Range Selector Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRangeChip(
                  context,
                  ref,
                  label: 'Today',
                  range: ReportTimeRange.today,
                  selectedRange: selectedRange,
                ),
                const SizedBox(width: 8),
                _buildRangeChip(
                  context,
                  ref,
                  label: 'Last 7 Days',
                  range: ReportTimeRange.last7Days,
                  selectedRange: selectedRange,
                ),
                const SizedBox(width: 8),
                _buildRangeChip(
                  context,
                  ref,
                  label: 'Last 30 Days',
                  range: ReportTimeRange.last30Days,
                  selectedRange: selectedRange,
                ),
                const SizedBox(width: 8),
                _buildRangeChip(
                  context,
                  ref,
                  label: 'All Time',
                  range: ReportTimeRange.allTime,
                  selectedRange: selectedRange,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          reportAsync.when(
            data: (data) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI Cards Grid (2x2)
                  Row(
                    children: [
                      Expanded(
                        child: _AnalyticsCard(
                          title: 'Gross Revenue',
                          value: CurrencyFormatter.formatPaise(data.totalSalesPaise),
                          subtitle: '${data.totalTransactions} bills logged',
                          icon: Icons.trending_up_rounded,
                          color: const Color(0xFF0D9488),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AnalyticsCard(
                          title: 'Net Profit',
                          value: CurrencyFormatter.formatPaise(data.netProfitPaise),
                          subtitle: data.totalSalesPaise > 0
                              ? '${((data.netProfitPaise / data.totalSalesPaise) * 100).clamp(0, 100).toStringAsFixed(1)}% margin'
                              : '0% margin',
                          icon: Icons.savings_outlined,
                          color: const Color(0xFF4F46E5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _AnalyticsCard(
                          title: 'Stock Inward (Cost)',
                          value: CurrencyFormatter.formatPaise(data.totalPurchasesPaise),
                          subtitle: 'Supplier bills',
                          icon: Icons.shopping_bag_outlined,
                          color: const Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AnalyticsCard(
                          title: 'Shop Expenses',
                          value: CurrencyFormatter.formatPaise(data.totalExpensesPaise),
                          subtitle: 'Rent, bills, overheads',
                          icon: Icons.receipt_long_outlined,
                          color: const Color(0xFFE11D48),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 7-Day Trend Chart Card
                  Container(
                    padding: const EdgeInsets.all(18),
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
                            Text(
                              'Sales Trend (Last 7 Days)',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Icon(
                              Icons.bar_chart_rounded,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Daily sales volume overview',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 190,
                          child: _buildBarChart(data.last7DaysSales, theme),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Payment Method Split Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Methods Breakdown',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPaymentRow(
                          context,
                          label: 'Cash Received',
                          amountPaise: data.paymentMethodSplitPaise['Cash'] ?? 0,
                          totalPaise: data.totalSalesPaise,
                          color: const Color(0xFF0D9488),
                          icon: Icons.payments_outlined,
                        ),
                        const SizedBox(height: 12),
                        _buildPaymentRow(
                          context,
                          label: 'UPI / Online QR',
                          amountPaise: data.paymentMethodSplitPaise['UPI'] ?? 0,
                          totalPaise: data.totalSalesPaise,
                          color: const Color(0xFF4F46E5),
                          icon: Icons.qr_code_2_rounded,
                        ),
                        const SizedBox(height: 12),
                        _buildPaymentRow(
                          context,
                          label: 'Customer Credit / Udhaar',
                          amountPaise: data.paymentMethodSplitPaise['Credit'] ?? 0,
                          totalPaise: data.totalSalesPaise,
                          color: const Color(0xFFDC2626),
                          icon: Icons.menu_book_rounded,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Top Selling Items Leaderboard
                  Container(
                    padding: const EdgeInsets.all(18),
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
                            Text(
                              'Top 5 Best-Selling Products',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Icon(Icons.star_rounded, color: Color(0xFFF59E0B)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (data.topProducts.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Text(
                                'No sales logged for this period yet.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: data.topProducts.length,
                            separatorBuilder: (context, index) => const Divider(height: 16),
                            itemBuilder: (context, index) {
                              final prod = data.topProducts[index];
                              return Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: index == 0
                                        ? const Color(0xFFF59E0B)
                                        : (index == 1
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFFCBD5E1)),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          prod.productName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          '${prod.unitsSold} units sold',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.formatPaise(prod.totalRevenuePaise),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: Color(0xFF0D9488),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Expense Category Breakdown Card
                  if (data.expenseCategoryBreakdownPaise.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.colorScheme.outline),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Store Expenses Distribution',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ...data.expenseCategoryBreakdownPaise.entries.map((e) {
                            final pct = data.totalExpensesPaise > 0
                                ? (e.value / data.totalExpensesPaise)
                                : 0.0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        e.key,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                      Text(
                                        CurrencyFormatter.formatPaise(e.value),
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: pct,
                                      minHeight: 6,
                                      backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.4),
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE11D48)),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error loading reports: $err'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<DailySalesDataPoint> points, ThemeData theme) {
    if (points.isEmpty) {
      return const Center(child: Text('No data'));
    }

    // Find max value in rupees for Y axis scaling
    double maxRupees = 100.0;
    for (final p in points) {
      final r = p.totalSalesPaise / 100.0;
      if (r > maxRupees) maxRupees = r;
    }
    maxRupees = math.max(maxRupees * 1.25, 500.0);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxRupees,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final pt = points[group.x.toInt()];
              return BarTooltipItem(
                '${pt.dayLabel}\n${CurrencyFormatter.formatPaise(pt.totalSalesPaise)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    points[idx].dayLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(points.length, (idx) {
          final pt = points[idx];
          final rupees = pt.totalSalesPaise / 100.0;
          return BarChartGroupData(
            x: idx,
            barRods: [
              BarChartRodData(
                toY: rupees,
                gradient: const LinearGradient(
                  colors: [Color(0xFF312E81), Color(0xFF6366F1)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 18,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxRupees,
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildPaymentRow(
    BuildContext context, {
    required String label,
    required int amountPaise,
    required int totalPaise,
    required Color color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final ratio = totalPaise > 0 ? (amountPaise / totalPaise).clamp(0.0, 1.0) : 0.0;
    final percentage = (ratio * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            Text(
              '${CurrencyFormatter.formatPaise(amountPaise)} ($percentage%)',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildRangeChip(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required ReportTimeRange range,
    required ReportTimeRange selectedRange,
  }) {
    final isSelected = (range == selectedRange);
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        ref.read(selectedReportTimeRangeProvider.notifier).state = range;
      },
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.18),
      checkmarkColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
      ),
      side: BorderSide(
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _AnalyticsCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
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
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

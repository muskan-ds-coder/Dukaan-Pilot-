import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../customers/presentation/customer_list_screen.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../inventory/presentation/inventory_screen.dart';
import '../../sales/presentation/sales_screen.dart';
import '../../../data/sync/sync_engine.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final currentThemeMode = ref.watch(appThemeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Settings & Operations'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Business Profile Header Card
          Container(
            padding: const EdgeInsets.all(18),
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
                  child: Icon(
                    Icons.store_rounded,
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authState.business?.name ?? 'My Dukaan',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Category: ${authState.business?.category ?? "General Store"}',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Currency: ${authState.business?.currency ?? "INR (₹)"}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 1: Store Operations
          Text(
            'STORE OPERATIONS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),

          ListTile(
            leading: const Icon(Icons.bar_chart_rounded, color: Color(0xFF4F46E5)),
            title: const Text('Business Reports & Analytics'),
            subtitle: const Text('Sales trends, margins, top products, and export'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () => context.push('/reports'),
          ),
          const Divider(height: 1),

          ListTile(
            leading: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF0F766E)),
            title: const Text('Inward Purchases & Bills'),
            subtitle: const Text('Record wholesale stock inward & invoices'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () => context.push('/purchases'),
          ),
          const Divider(height: 1),

          ListTile(
            leading: const Icon(Icons.people_outline_rounded, color: Color(0xFF2563EB)),
            title: const Text('Wholesale Suppliers'),
            subtitle: const Text('Manage supplier contacts & vendors'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () => context.push('/suppliers'),
          ),
          const Divider(height: 1),

          ListTile(
            leading: const Icon(Icons.receipt_long_outlined, color: Color(0xFFDC2626)),
            title: const Text('Daily Store Expenses'),
            subtitle: const Text('Rent, electricity, wages, tea/snacks'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () => context.push('/expenses'),
          ),
          const Divider(height: 1),

          ListTile(
            leading: const Icon(Icons.history_edu_outlined, color: Color(0xFF6366F1)),
            title: const Text('Stock Movements Audit Log'),
            subtitle: const Text('Auditable log of inward, sales, and corrections'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () => context.push('/stock-movements'),
          ),
          const Divider(height: 1),

          ListTile(
            leading: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEA580C)),
            title: const Text('Low Stock Alerts & Reorder Cockpit'),
            subtitle: const Text('Suggested reorder quantities for critical SKUs'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () => context.push('/low-stock'),
          ),
          const SizedBox(height: 24),

          // Section 2: Preferences
          Text(
            'PREFERENCES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),

          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('App Theme'),
            subtitle: Text(
              currentThemeMode == ThemeMode.system
                  ? 'System Default'
                  : (currentThemeMode == ThemeMode.dark ? 'Dark Mode' : 'Light Mode'),
            ),
            trailing: DropdownButton<ThemeMode>(
              value: currentThemeMode,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(appThemeModeProvider.notifier).state = mode;
                }
              },
            ),
          ),
          const Divider(height: 1),

          ListTile(
            leading: const Icon(Icons.mic_outlined),
            title: const Text('Voice Assistant Language'),
            subtitle: const Text('Hinglish / Hindi / English (Auto-detect)'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Auto-detects Hindi, Hinglish, and English voice speech.')),
              );
            },
          ),
          const SizedBox(height: 24),

          // Section 3: Data & Testing
          Text(
            'DATA & DEVELOPER TESTING',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),

          ListTile(
            leading: const Icon(Icons.refresh_rounded, color: Color(0xFF0D9488)),
            title: const Text('Reload Demo Store Data'),
            subtitle: const Text('Resets sample cosmetics products, customers, and udhaar'),
            onTap: () async {
              await ref.read(authNotifierProvider.notifier).signInWithDemo();
              ref.invalidate(dashboardMetricsProvider);
              ref.invalidate(productsListProvider);
              ref.invalidate(customersListProvider);
              ref.invalidate(salesListProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Demo store data reloaded successfully!')),
                );
              }
            },
          ),
          const Divider(height: 1),

          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('Export Business Data'),
            subtitle: const Text('Download products, sales, and udhaar in CSV format'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exporting local SQLite database to CSV...')),
              );
            },
          ),
          const Divider(height: 1),

          // Cloud Sync Engine & Offline Queue
          Consumer(
            builder: (context, ref, _) {
              final syncState = ref.watch(syncEngineProvider);
              return ListTile(
                leading: Icon(
                  syncState.isSyncing
                      ? Icons.sync_rounded
                      : (syncState.pendingCount > 0 ? Icons.cloud_upload_outlined : Icons.cloud_done_rounded),
                  color: syncState.isSyncing
                      ? const Color(0xFF6366F1)
                      : (syncState.pendingCount > 0 ? const Color(0xFFF97316) : const Color(0xFF0D9488)),
                ),
                title: const Text('Cloud Sync & Offline Queue'),
                subtitle: Text(
                  syncState.isSyncing
                      ? 'Syncing offline queue with server...'
                      : (syncState.pendingCount > 0
                          ? '${syncState.pendingCount} offline changes pending'
                          : '100% Synced • Offline-First Active'),
                ),
                trailing: syncState.isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () async {
                          final success = await ref.read(syncEngineProvider.notifier).syncNow();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Cloud sync completed successfully!'
                                      : 'Offline changes queued locally. Safe to continue offline.',
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text('Sync', style: TextStyle(fontSize: 12)),
                      ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Section 4: About & Account
          Text(
            'ACCOUNT & SYSTEM',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),

          const ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('About DukaanPilot AI'),
            subtitle: Text('Version 1.0.0 (Build 1) • Android-First'),
          ),
          const Divider(height: 1),

          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.red),
            title: const Text('Log Out', style: TextStyle(color: Colors.red)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to sign out of this store?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Log Out'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ref.read(authNotifierProvider.notifier).signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

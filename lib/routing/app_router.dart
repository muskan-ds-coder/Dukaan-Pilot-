import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/customers/presentation/add_customer_screen.dart';
import '../features/customers/presentation/customer_detail_screen.dart';
import '../features/customers/presentation/customer_list_screen.dart';
import '../features/dashboard/presentation/home_dashboard_screen.dart';
import '../features/expenses/presentation/add_expense_screen.dart';
import '../features/expenses/presentation/expenses_screen.dart';
import '../features/inventory/presentation/inventory_screen.dart';
import '../features/inventory/presentation/low_stock_screen.dart';
import '../features/inventory/presentation/stock_movements_screen.dart';
import '../features/invoice_scanner/presentation/invoice_scanner_screen.dart';
import '../features/onboarding/presentation/business_setup_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/onboarding/presentation/splash_screen.dart';
import '../features/products/presentation/add_product_screen.dart';
import '../features/products/presentation/edit_product_screen.dart';
import '../features/products/presentation/product_detail_screen.dart';
import '../features/purchases/presentation/create_purchase_screen.dart';
import '../features/purchases/presentation/purchases_screen.dart';
import '../features/purchases/presentation/suppliers_screen.dart';
import '../features/sales/presentation/create_sale_screen.dart';
import '../features/sales/presentation/sale_detail_screen.dart';
import '../features/sales/presentation/sales_screen.dart';
import '../features/reports/presentation/reports_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/voice_assistant/presentation/voice_assistant_screen.dart';
import 'main_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      // Splash & Auth
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/business-setup',
        builder: (context, state) => const BusinessSetupScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // 5-Tab Stateful Shell Navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeDashboardScreen(),
              ),
            ],
          ),
          // Branch 1: Inventory
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inventory',
                builder: (context, state) => const InventoryScreen(),
              ),
            ],
          ),
          // Branch 2: Sales
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/sales',
                builder: (context, state) => const SalesScreen(),
              ),
            ],
          ),
          // Branch 3: Customers
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/customers',
                builder: (context, state) => const CustomerListScreen(),
              ),
            ],
          ),
          // Branch 4: More / Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Products & Inventory Sub-routes
      GoRoute(
        path: '/add-product',
        builder: (context, state) => const AddProductScreen(),
      ),
      GoRoute(
        path: '/products/:id',
        builder: (context, state) => ProductDetailScreen(
          productId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/edit-product/:id',
        builder: (context, state) => EditProductScreen(
          productId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/stock-movements',
        builder: (context, state) => const StockMovementsScreen(),
      ),
      GoRoute(
        path: '/low-stock',
        builder: (context, state) => const LowStockScreen(),
      ),

      // Sales POS Sub-routes
      GoRoute(
        path: '/create-sale',
        builder: (context, state) => const CreateSaleScreen(),
      ),
      GoRoute(
        path: '/sales/:id',
        builder: (context, state) => SaleDetailScreen(
          saleId: state.pathParameters['id']!,
        ),
      ),

      // Customers & Udhaar Sub-routes
      GoRoute(
        path: '/add-customer',
        builder: (context, state) => const AddCustomerScreen(),
      ),
      GoRoute(
        path: '/customers/:id',
        builder: (context, state) => CustomerDetailScreen(
          customerId: state.pathParameters['id']!,
        ),
      ),

      // Purchases & Suppliers Sub-routes
      GoRoute(
        path: '/purchases',
        builder: (context, state) => const PurchasesScreen(),
      ),
      GoRoute(
        path: '/create-purchase',
        builder: (context, state) => const CreatePurchaseScreen(),
      ),
      GoRoute(
        path: '/suppliers',
        builder: (context, state) => const SuppliersScreen(),
      ),

      // Expenses Sub-routes
      GoRoute(
        path: '/expenses',
        builder: (context, state) => const ExpensesScreen(),
      ),
      GoRoute(
        path: '/add-expense',
        builder: (context, state) => const AddExpenseScreen(),
      ),

      // Voice & Document AI Tools
      GoRoute(
        path: '/voice-assistant',
        builder: (context, state) => const VoiceAssistantScreen(),
      ),
      GoRoute(
        path: '/invoice-scanner',
        builder: (context, state) => const InvoiceScannerScreen(),
      ),
      // Reports & Business Analytics
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
    ],
  );
});

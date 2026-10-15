import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/business.dart';
import '../../data/local/database_helper.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/business_repository_impl.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../data/repositories/purchase_repository_impl.dart';
import '../../data/repositories/sale_repository_impl.dart';
import '../../data/repositories/supplier_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/business_repository.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/purchase_repository.dart';
import '../../domain/repositories/sale_repository.dart';
import '../../domain/repositories/supplier_repository.dart';

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return AuthRepositoryImpl(dbHelper: dbHelper);
});

final businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return BusinessRepositoryImpl(dbHelper: dbHelper);
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return ProductRepositoryImpl(dbHelper: dbHelper);
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return CustomerRepositoryImpl(dbHelper: dbHelper);
});

final saleRepositoryProvider = Provider<SaleRepository>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return SaleRepositoryImpl(dbHelper: dbHelper);
});

final supplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return SupplierRepositoryImpl(dbHelper: dbHelper);
});

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return PurchaseRepositoryImpl(dbHelper: dbHelper);
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return ExpenseRepositoryImpl(dbHelper: dbHelper);
});

final currentBusinessProvider = FutureProvider<Business?>((ref) async {
  final businessRepo = ref.watch(businessRepositoryProvider);
  return businessRepo.getCurrentBusiness();
});

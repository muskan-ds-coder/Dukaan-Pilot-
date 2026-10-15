import '../entities/supplier.dart';

abstract class SupplierRepository {
  Future<List<Supplier>> getSuppliers({String? query});
  Future<Supplier?> getSupplierById(String id);
  Future<Supplier> addSupplier(Supplier supplier);
  Future<Supplier> updateSupplier(Supplier supplier);
  Future<void> deleteSupplier(String id);
}

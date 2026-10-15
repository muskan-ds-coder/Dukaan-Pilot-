import '../entities/customer.dart';
import '../entities/ledger_entry.dart';

abstract class CustomerRepository {
  Future<List<Customer>> getCustomers({String? query});
  Future<Customer?> getCustomerById(String id);
  Future<Customer> addCustomer(Customer customer);
  Future<Customer> updateCustomer(Customer customer);
  Future<void> recordPayment({
    required String customerId,
    required int amountPaise,
    String? note,
  });
  Future<List<LedgerEntry>> getCustomerLedger(String customerId);
  Future<int> getTotalOutstandingUdhaar();
}

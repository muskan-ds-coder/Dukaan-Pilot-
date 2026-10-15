import '../entities/business.dart';

abstract class BusinessRepository {
  Future<Business?> getCurrentBusiness();
  Future<Business> setupBusiness({
    required String name,
    required String ownerName,
    required String category,
    String? phone,
    String currency = 'INR',
  });
  Future<void> updateBusiness(Business business);
}

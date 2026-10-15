/// Customer credit / Udhaar ledger entry
class LedgerEntry {
  final String id;
  final String businessId;
  final String customerId;
  final String? customerName;
  final String type; // CREDIT, PAYMENT, ADJUSTMENT
  final int amountPaise;
  final String? referenceId; // saleId if related to a sale
  final String? description;
  final DateTime createdAt;
  final String syncStatus;

  const LedgerEntry({
    required this.id,
    required this.businessId,
    required this.customerId,
    this.customerName,
    required this.type,
    required this.amountPaise,
    this.referenceId,
    this.description,
    required this.createdAt,
    this.syncStatus = 'PENDING',
  });

  bool get isCredit => type == 'CREDIT';
  bool get isPayment => type == 'PAYMENT';

  LedgerEntry copyWith({
    String? id,
    String? businessId,
    String? customerId,
    String? customerName,
    String? type,
    int? amountPaise,
    String? referenceId,
    String? description,
    DateTime? createdAt,
    String? syncStatus,
  }) {
    return LedgerEntry(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      type: type ?? this.type,
      amountPaise: amountPaise ?? this.amountPaise,
      referenceId: referenceId ?? this.referenceId,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

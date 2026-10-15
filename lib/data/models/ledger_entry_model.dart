import '../../domain/entities/ledger_entry.dart';

class LedgerEntryModel extends LedgerEntry {
  const LedgerEntryModel({
    required super.id,
    required super.businessId,
    required super.customerId,
    super.customerName,
    required super.type,
    required super.amountPaise,
    super.referenceId,
    super.description,
    required super.createdAt,
    super.syncStatus = 'PENDING',
  });

  factory LedgerEntryModel.fromEntity(LedgerEntry entity) {
    return LedgerEntryModel(
      id: entity.id,
      businessId: entity.businessId,
      customerId: entity.customerId,
      customerName: entity.customerName,
      type: entity.type,
      amountPaise: entity.amountPaise,
      referenceId: entity.referenceId,
      description: entity.description,
      createdAt: entity.createdAt,
      syncStatus: entity.syncStatus,
    );
  }

  factory LedgerEntryModel.fromMap(Map<String, dynamic> map, {String? customerName}) {
    return LedgerEntryModel(
      id: map['id'] as String,
      businessId: map['business_id'] as String,
      customerId: map['customer_id'] as String,
      customerName: customerName ?? (map['customer_name'] as String?),
      type: map['type'] as String,
      amountPaise: map['amount_paise'] as int,
      referenceId: map['reference_id'] as String?,
      description: map['description'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      syncStatus: (map['sync_status'] as String?) ?? 'PENDING',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'customer_id': customerId,
      'type': type,
      'amount_paise': amountPaise,
      'reference_id': referenceId,
      'description': description,
      'created_at': createdAt.millisecondsSinceEpoch,
      'sync_status': syncStatus,
    };
  }
}

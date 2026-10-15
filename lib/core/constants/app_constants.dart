/// Global application constants for DukaanPilot AI
class AppConstants {
  static const String appName = 'DukaanPilot AI';
  static const String appShortName = 'DukaanPilot';
  static const String appTagline = 'Run your shop by simply speaking.';
  static const String appVersion = '1.0.0';

  // Currency
  static const String defaultCurrencyCode = 'INR';
  static const String currencySymbol = '₹';

  // Business Categories
  static const List<String> businessCategories = [
    'Cosmetics',
    'Kirana',
    'General Store',
    'Fashion',
    'Jewellery',
    'Footwear',
    'Electronics',
    'Other',
  ];

  // Product Units
  static const List<String> productUnits = [
    'Piece',
    'Box',
    'Pack',
    'Bottle',
    'Kg',
    'Gram',
    'Litre',
    'Other',
  ];

  // Stock Movement Types
  static const String movementPurchase = 'PURCHASE';
  static const String movementSale = 'SALE';
  static const String movementAdjustmentIn = 'ADJUSTMENT_IN';
  static const String movementAdjustmentOut = 'ADJUSTMENT_OUT';
  static const String movementReturnIn = 'RETURN_IN';
  static const String movementReturnOut = 'RETURN_OUT';
  static const String movementDamage = 'DAMAGE';
  static const String movementCorrection = 'CORRECTION';

  // Payment Methods
  static const List<String> paymentMethods = [
    'Cash',
    'UPI',
    'Card',
    'Credit/Udhaar',
    'Split Payment',
    'Other',
  ];

  // Customer Ledger Entry Types
  static const String ledgerCredit = 'CREDIT';
  static const String ledgerPayment = 'PAYMENT';
  static const String ledgerAdjustment = 'ADJUSTMENT';

  // Expense Categories
  static const List<String> expenseCategories = [
    'Rent',
    'Electricity',
    'Transport',
    'Salary',
    'Packaging',
    'Supplier',
    'Marketing',
    'Other',
  ];

  // Sync States
  static const String syncPending = 'PENDING';
  static const String syncSyncing = 'SYNCING';
  static const String syncSynced = 'SYNCED';
  static const String syncFailed = 'FAILED';

  // Minimum Stock Default
  static const int defaultMinimumStock = 5;

  // Local Storage Keys
  static const String keyCurrentBusinessId = 'current_business_id';
  static const String keyCurrentUserId = 'current_user_id';
  static const String keyIsFirstLaunch = 'is_first_launch';
  static const String keyThemeMode = 'app_theme_mode';
}

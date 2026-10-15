import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/currency_formatter.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      await _notificationsPlugin.initialize(initSettings);
      _isInitialized = true;
    } catch (_) {
      // Gracefully handle environments without native platform channels (e.g. unit test runner)
    }
  }

  Future<void> showLowStockAlert({
    required String productName,
    required int currentStock,
    required int minimumStock,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'dukaanpilot_inventory_channel',
      'Inventory Alerts',
      channelDescription: 'Alerts for low stock and out-of-stock items',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.show(
        productName.hashCode,
        '⚠️ Low Stock Alert: $productName',
        'Only $currentStock items left in stock (Minimum threshold: $minimumStock). Reorder soon!',
        details,
      );
    } catch (_) {}
  }

  Future<void> showDailySummaryNotification({
    required int todaySalesPaise,
    required int transactionCount,
    required int pendingUdhaarPaise,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'dukaanpilot_briefing_channel',
      'Daily Business Briefings',
      channelDescription: 'Morning briefings and evening sales closing summaries',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    final formattedSales = CurrencyFormatter.formatPaise(todaySalesPaise);
    final formattedUdhaar = CurrencyFormatter.formatPaise(pendingUdhaarPaise);

    try {
      await _notificationsPlugin.show(
        1001,
        '📊 Daily Store Summary: $formattedSales Today',
        'Completed $transactionCount sales bills. Outstanding Khata balance: $formattedUdhaar.',
        details,
      );
    } catch (_) {}
  }
}

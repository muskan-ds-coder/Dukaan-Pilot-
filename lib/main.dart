import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/notification_service.dart';
import 'data/local/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite local database
  await DatabaseHelper.instance.database;

  // Initialize Notification Service
  await NotificationService().initialize();

  runApp(
    const ProviderScope(
      child: DukaanPilotApp(),
    ),
  );
}

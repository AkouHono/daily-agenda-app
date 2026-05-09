import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/hive_service.dart';
import 'core/theme.dart';
import 'features/agenda/agenda_screen.dart';
import 'features/notifications/notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully with options');
  } catch (e) {
    print('Firebase initialization failed: $e');
  }

  // Initialize Hive and Notifications
  await HiveService.init();
  await NotificationService.init();

  runApp(
    const ProviderScope(
      child: DailyAgendaApp(),
    ),
  );
}

class DailyAgendaApp extends ConsumerWidget {
  const DailyAgendaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Daily Agenda',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AgendaScreen(),
    );
  }
}

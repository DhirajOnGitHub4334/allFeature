import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:new_app/Notification/notification_service.dart';
import 'package:new_app/Screen/chat_page.dart';
import 'package:new_app/Screen/home_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await NotificationService.instance.initialize();

  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'All Feature',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'FlutterApp'),
      routes: {
        '/chat': (context) => const ChatScreen(),
      },
    );
  }
}

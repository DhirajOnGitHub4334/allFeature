import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:new_app/Screen/chat_page.dart';
import 'package:new_app/firebase_options.dart';
import 'package:new_app/main.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.setupFlutterNotifications();
  await NotificationService.instance.showFlutterNotification(message);
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  log('Handling a background message ${message.messageId}');
}

class NotificationService {
  static final NotificationService instance = NotificationService();

  final messaging = FirebaseMessaging.instance;

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  bool isFlutterLocalNotificationsInitialized = false;

  late AndroidNotificationChannel channel;

  Future<void> initialize() async {
    //pass Background Message Handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    //request Permission
    await requestPermission();

    //Set Up Message Handler
    await setUpMessageHandler();

    //set Up mesage Notification
    await setupFlutterNotifications();

    // Get FCM TOKEN
    final token = await messaging.getToken();
    log("FCM Token : $token");

    await subscribeToTopic("all_devices");
  }

  Future<void> requestPermission() async {
    final setting = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: true,
      announcement: true,
    );
  }

  Future<void> setupFlutterNotifications() async {
    if (isFlutterLocalNotificationsInitialized) {
      return;
    }
    channel = const AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const initilizationSettingsAndroid =
        AndroidInitializationSettings("@mipmap/ic_launcher");

    //iOS Set up
    final initializationSettingsIos = DarwinInitializationSettings();

    final initializationSetting = InitializationSettings(
      android: initilizationSettingsAndroid,
      iOS: initializationSettingsIos,
    );

    // Flutter Notification Setup
    await flutterLocalNotificationsPlugin.initialize(initializationSetting,
        onDidReceiveNotificationResponse: (details) {
      if (details.payload == 'chat') {
        handleBackgroundMessage(details.payload!);
      }
    });

    isFlutterLocalNotificationsInitialized = true;
  }

  Future<void> setUpMessageHandler() async {
    //Foreground Message
    FirebaseMessaging.onMessage.listen((message) {
      log("Foreground Message Data : $message");
      showFlutterNotification(message);
    });

    //Background or Terminated App Message Handler
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      log("Handle Message when App in Background and Terminated Condition : $message ");
      handleBackgroundMessage(message.data['type']);
    });

    //Handle Message When App open via Message
    final initializeMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initializeMessage != null) {
      log("Initialize Message And Navigate : $initializeMessage");
      handleBackgroundMessage(initializeMessage.data['type']);
    }
  }

  showFlutterNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    if (notification != null && android != null && !kIsWeb) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['type'].toString(),
      );
    }
  }

  void handleBackgroundMessage(String message) {
    if (message == "chat") {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => const ChatScreen(),
        ),
      );
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await FirebaseMessaging.instance.subscribeToTopic(topic);
    print("Sunscribe Topic : $topic");
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint("Handling background FCM message: ${message.messageId}");
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final Set<String> _notifiedSurgeIds = {};
  Timer? _pollingTimer;
  bool _isInitialized = false;

  static const AndroidNotificationChannel _surgeChannel = AndroidNotificationChannel(
    'surge_radar_channel',
    'Surge Radar Alerts',
    description: 'High priority alerts for sudden 10%-20%+ option momentum and breakout trades',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      // 1. Initialize Firebase
      await Firebase.initializeApp();
      debugPrint("Firebase initialized successfully");

      // 2. Set background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Initialize Flutter Local Notifications for heads-up foreground banners
      const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings = InitializationSettings(android: androidInit);

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint("Notification tapped: ${response.payload}");
        },
      );

      // Create Android Notification Channel
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_surgeChannel);

      // 4. Request notification permissions (required on Android 13+)
      final NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );
      debugPrint('FCM Authorization status: ${settings.authorizationStatus}');

      // 5. Subscribe to surge radar topics
      await FirebaseMessaging.instance.subscribeToTopic('surge_radar_alerts');
      await FirebaseMessaging.instance.subscribeToTopic('all_users');

      // 6. Get device FCM Token and register with backend
      final String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        debugPrint("FCM Device Token: $token");
        await ApiService().registerFCMToken(token);
      }

      // Listen for token refreshes
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        debugPrint("FCM Token refreshed: $newToken");
        await ApiService().registerFCMToken(newToken);
      });

      // 7. Handle foreground FCM messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got FCM foreground message: ${message.messageId}');
        _showNotificationFromRemoteMessage(message);
      });

      // 8. Handle notification tap opening app
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('App opened from notification: ${message.data}');
      });

    } catch (e) {
      debugPrint("Firebase / FCM setup notice: $e");
    }

    // 9. Real-time Instant Sync Poller:
    // Polls backend every 6s so that if React gets an unread notification on /surge-radar,
    // the Flutter app immediately displays the heads-up notification in real-time!
    startSurgeAlertPoller();
  }

  void _showNotificationFromRemoteMessage(RemoteMessage message) {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? '⚡ Surge Radar Alert';
    final body = notification?.body ?? message.data['body'] ?? 'New sudden momentum trade detected!';
    final id = message.messageId.hashCode;

    showLocalSurgeNotification(
      id: id,
      title: title,
      body: body,
      payload: jsonEncode(message.data),
    );
  }

  Future<void> showLocalSurgeNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'surge_radar_channel',
      'Surge Radar Alerts',
      channelDescription: 'High priority alerts for sudden option momentum and breakout trades',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Surge Radar',
      color: Color(0xFF10B981),
      enableLights: true,
      enableVibration: true,
      playSound: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformDetails,
      payload: payload,
    );
  }

  void startSurgeAlertPoller() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 6), (_) async {
      try {
        final surgeData = await ApiService().getSurgeRadar();
        final suggestions = (surgeData['suggestions'] as List<dynamic>?) ?? [];
        final minConf = (surgeData['min_confidence'] as num?)?.toInt() ?? 80;
        final minSurge = (surgeData['min_surge_pct'] as num?)?.toDouble() ?? 10.0;

        for (final item in suggestions) {
          if (item is! Map<String, dynamic>) continue;
          final id = item['id']?.toString() ?? '';
          if (id.isEmpty) continue;

          final conf = (item['confidence_score'] as num?)?.toInt() ?? 0;
          final surgePct = (item['surge_pct'] as num?)?.toDouble() ?? 0.0;
          if (conf < minConf || surgePct < minSurge) continue;

          // If this surge alert was not yet shown as a push notification:
          if (!_notifiedSurgeIds.contains(id)) {
            _notifiedSurgeIds.add(id);

            // Seed existing alerts on app startup without spamming notifications
            if (_notifiedSurgeIds.length <= suggestions.length && _notifiedSurgeIds.length <= 3) {
              continue;
            }

            final symbol = item['symbol'] ?? 'INDEX';
            final strike = item['strike_price'] ?? '';
            final opt = item['option_type'] ?? '';
            final ltp = item['current_ltp'] ?? item['entry_price'];
            final t1 = item['target_1'] ?? '';
            final sl = item['stop_loss'] ?? '';
            final badge = item['surge_badge'] ?? '+$surgePct% Sudden Move';

            final title = '🔥 $symbol $strike $opt | $badge';
            final body = 'LTP: ₹$ltp | Buy Entry: ₹${item['entry_price']} | T1: ₹$t1 | SL: ₹$sl';

            await showLocalSurgeNotification(
              id: id.hashCode,
              title: title,
              body: body,
              payload: jsonEncode(item),
            );
          }
        }
      } catch (_) {}
    });
  }

  void dispose() {
    _pollingTimer?.cancel();
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mycondo/data/repositories/auth/profile_identity_service.dart';
import 'package:mycondo/services/push/push_session_binding_service.dart';
import 'package:mycondo/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

const _androidHighPriorityChannel = AndroidNotificationChannel(
  'mycondo_high_importance',
  'myCondo Notifications',
  description: 'Used for important condo updates.',
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> myCondoFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static const String _installationIdKey = 'push.installation_id';
  static const Uuid _uuid = Uuid();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final SupabaseClient _supabase = Supabase.instance.client;
  final ProfileIdentityService _identity = ProfileIdentityService();
  final PushSessionBindingService _bindingService = PushSessionBindingService();

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _openedMessageSubscription;
  bool _didInitialize = false;

  bool get _supportsPush {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> initialize() async {
    if (_didInitialize || !_supportsPush || Firebase.apps.isEmpty) {
      return;
    }

    if (kIsWeb) {
      final isSupported = await _messaging.isSupported();
      if (!isSupported) return;
    }

    if (!kIsWeb) {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings();
      const settings = InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
      );

      await _localNotifications.initialize(settings: settings);

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_androidHighPriorityChannel);

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    if (!kIsWeb) {
      _foregroundMessageSubscription?.cancel();
      _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen(
        _showForegroundNotification,
      );
    }

    _openedMessageSubscription?.cancel();
    _openedMessageSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (_) {},
    );

    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) async {
      try {
        await _upsertCurrentDeviceToken(token: token);
      } catch (error) {
        debugPrint('Push token refresh sync skipped: $error');
      }
    });

    _didInitialize = true;
  }

  Future<void> registerCurrentProfileDevice({
    bool requestPermission = true,
  }) async {
    if (!_supportsPush || Firebase.apps.isEmpty) return;

    try {
      if (kIsWeb && !await _messaging.isSupported()) {
        return;
      }

      await initialize();

      final profile = await _identity.getCurrentProfile();
      if (profile == null) return;

      final settings = requestPermission
          ? await _messaging.requestPermission(
              alert: true,
              badge: true,
              sound: true,
              provisional: false,
            )
          : await _messaging.getNotificationSettings();

      final isAllowed =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (!isAllowed) {
        await _deactivateInstallationTokens(profileId: profile.id);
        return;
      }

      if (kIsWeb && _webVapidKeyOrNull() == null) {
        debugPrint(
          'Push registration skipped on web: missing FIREBASE_WEB_VAPID_KEY.',
        );
        return;
      }

      final token = await _messaging.getToken(
        vapidKey: kIsWeb ? _webVapidKeyOrNull() : null,
      );
      if (token == null || token.trim().isEmpty) {
        if (kIsWeb) {
          debugPrint(
            'Push registration skipped on web: token unavailable (check FIREBASE_WEB_VAPID_KEY and firebase-messaging-sw.js).',
          );
        }
        return;
      }

      await _upsertCurrentDeviceToken(token: token, profileId: profile.id);
    } catch (error) {
      debugPrint('Push registration skipped: $error');
    }
  }

  Future<void> unregisterCurrentProfileDevice({String? profileId}) async {
    if (!_supportsPush || Firebase.apps.isEmpty) return;

    try {
      await _deactivateInstallationTokens(profileId: profileId);
    } catch (error) {
      debugPrint('Push deactivation skipped: $error');
    }
  }

  Future<void> _upsertCurrentDeviceToken({
    required String token,
    String? profileId,
  }) async {
    final profile = profileId == null
        ? await _identity.getCurrentProfile()
        : null;
    final resolvedProfileId = profileId ?? profile?.id;
    if (resolvedProfileId == null || resolvedProfileId.isEmpty) return;

    final currentProfile = profile ?? await _identity.getCurrentProfile();
    final installationId = await _getOrCreateInstallationId();
    final now = DateTime.now().toUtc().toIso8601String();
    final platform = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      _ => kIsWeb ? 'web' : 'unknown',
    };

    await _deactivateOtherProfilesForInstallation(
      installationId: installationId,
      keepProfileId: resolvedProfileId,
    );

    await _supabase.from('device_push_tokens').upsert({
      'installation_id': installationId,
      'profile_id': resolvedProfileId,
      'role': currentProfile?.role,
      'platform': platform,
      'push_token': token,
      'is_active': true,
      'last_seen_at': now,
      'deactivated_at': null,
    }, onConflict: 'push_token');

    await _bindingService.bindPersistentSession(profileId: resolvedProfileId);
  }

  String? _webVapidKeyOrNull() {
    final vapid = AppConfig.firebaseWebVapidKey.trim();
    return vapid.isEmpty ? null : vapid;
  }

  Future<void> _deactivateInstallationTokens({String? profileId}) async {
    final installationId = await _getOrCreateInstallationId();
    final query = _supabase
        .from('device_push_tokens')
        .update({
          'is_active': false,
          'deactivated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('installation_id', installationId)
        .eq('is_active', true);

    if (profileId != null && profileId.trim().isNotEmpty) {
      await query.eq('profile_id', profileId);
    } else {
      await query;
    }

    await _bindingService.clearBinding();
  }

  Future<void> _deactivateOtherProfilesForInstallation({
    required String installationId,
    required String keepProfileId,
  }) async {
    await _supabase
        .from('device_push_tokens')
        .update({
          'is_active': false,
          'deactivated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('installation_id', installationId)
        .neq('profile_id', keepProfileId)
        .eq('is_active', true);
  }

  Future<String> _getOrCreateInstallationId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_installationIdKey)?.trim();
    if (existing != null && existing.isNotEmpty) return existing;

    final generated = _uuid.v4();
    await prefs.setString(_installationIdKey, generated);
    return generated;
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title?.trim();
    final body = notification?.body?.trim();
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidHighPriorityChannel.id,
        _androidHighPriorityChannel.name,
        channelDescription: _androidHighPriorityChannel.description,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final payload = message.data.isEmpty ? null : jsonEncode(message.data);
    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title ?? 'myCondo',
      body: body ?? 'You have a new notification.',
      notificationDetails: details,
      payload: payload,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mycondo/services/push/push_notification_service.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  try {
    final didInitializeFirebase = await _initializeFirebase();
    if (didInitializeFirebase) {
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(
          myCondoFirebaseMessagingBackgroundHandler,
        );
      }
      await PushNotificationService.instance.initialize();
    }
  } catch (error) {
    debugPrint('Firebase initialization skipped: $error');
  }

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const MyCondoApp());
}

Future<bool> _initializeFirebase() async {
  if (Firebase.apps.isNotEmpty) return true;

  if (kIsWeb) {
    final options = _firebaseWebOptionsFromEnv();
    if (options == null) {
      debugPrint(
        'Firebase web init skipped: missing FIREBASE_WEB_* values in .env',
      );
      return false;
    }
    await Firebase.initializeApp(options: options);
    return true;
  }

  await Firebase.initializeApp();
  return true;
}

FirebaseOptions? _firebaseWebOptionsFromEnv() {
  final apiKey = dotenv.env['FIREBASE_WEB_API_KEY']?.trim() ?? '';
  final appId = dotenv.env['FIREBASE_WEB_APP_ID']?.trim() ?? '';
  final messagingSenderId =
      dotenv.env['FIREBASE_MESSAGING_SENDER_ID']?.trim() ?? '';
  final projectId = dotenv.env['FIREBASE_WEB_PROJECT_ID']?.trim() ?? '';

  if (apiKey.isEmpty ||
      appId.isEmpty ||
      messagingSenderId.isEmpty ||
      projectId.isEmpty) {
    return null;
  }

  final authDomainRaw = dotenv.env['FIREBASE_WEB_AUTH_DOMAIN']?.trim() ?? '';
  final storageBucketRaw =
      dotenv.env['FIREBASE_WEB_STORAGE_BUCKET']?.trim() ?? '';
  final measurementIdRaw =
      dotenv.env['FIREBASE_WEB_MEASUREMENT_ID']?.trim() ?? '';

  final authDomain = authDomainRaw.isEmpty
      ? '$projectId.firebaseapp.com'
      : authDomainRaw;
  final storageBucket = storageBucketRaw.isEmpty
      ? '$projectId.appspot.com'
      : storageBucketRaw;

  return FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    authDomain: authDomain,
    storageBucket: storageBucket,
    measurementId: measurementIdRaw.isEmpty ? null : measurementIdRaw,
  );
}

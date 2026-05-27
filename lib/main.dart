import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mycondo/config/app_config.dart';
import 'package:mycondo/services/push/push_notification_service.dart';
import 'package:mycondo/startup/configuration_error_app.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final missingConfig = AppConfig.missingRequiredValues;
  if (missingConfig.isNotEmpty) {
    runApp(ConfigurationErrorApp(missingValues: missingConfig));
    return;
  }

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

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
  final apiKey = AppConfig.firebaseWebApiKey.trim();
  final appId =  AppConfig.firebaseWebAppId.trim();
  final messagingSenderId = AppConfig.firebaseMessagingSenderId.trim();
  final projectId =  AppConfig.firebaseWebProjectId.trim();

  if (apiKey.isEmpty ||
      appId.isEmpty ||
      messagingSenderId.isEmpty ||
      projectId.isEmpty) {
    return null;
  }

  final authDomainRaw = AppConfig.firebaseWebAuthDomain.trim();
  final storageBucketRaw = AppConfig.firebaseWebStorageBucket.trim();
  final measurementIdRaw = AppConfig.firebaseWebMeasurementId.trim();
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

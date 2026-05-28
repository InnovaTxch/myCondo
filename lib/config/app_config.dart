class AppConfig {
  const AppConfig._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static const firebaseWebApiKey = String.fromEnvironment('FIREBASE_WEB_API_KEY');
  static const firebaseWebAppId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
  static const firebaseMessagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const firebaseWebProjectId = String.fromEnvironment('FIREBASE_WEB_PROJECT_ID');
  static const firebaseWebAuthDomain = String.fromEnvironment('FIREBASE_WEB_AUTH_DOMAIN');
  static const firebaseWebStorageBucket = String.fromEnvironment('FIREBASE_WEB_STORAGE_BUCKET');
  static const firebaseWebMeasurementId = String.fromEnvironment('FIREBASE_WEB_MEASUREMENT_ID');
  static const firebaseWebVapidKey = String.fromEnvironment('FIREBASE_WEB_VAPID_KEY');

  static List<String> get missingRequiredValues {
    final missing = <String>[];

    if (supabaseUrl.trim().isEmpty) missing.add('SUPABASE_URL');
    if (supabaseAnonKey.trim().isEmpty) missing.add('SUPABASE_ANON_KEY');

    return missing;
  }
}
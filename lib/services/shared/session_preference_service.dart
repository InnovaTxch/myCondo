import 'package:shared_preferences/shared_preferences.dart';

class SessionPreferenceService {
  SessionPreferenceService._internal();

  static final SessionPreferenceService _instance =
      SessionPreferenceService._internal();

  factory SessionPreferenceService() => _instance;

  static const String _keepSignedInKey = 'auth.keep_signed_in';
  static const String _retainForOnboardingKey =
      'auth.retain_session_for_onboarding';

  bool _hasEphemeralSessionThisLaunch = false;

  Future<void> applyLoginChoice({required bool keepSignedIn}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keepSignedInKey, keepSignedIn);
    _hasEphemeralSessionThisLaunch = !keepSignedIn;
  }

  Future<bool> isKeepSignedInEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keepSignedInKey) ?? false;
  }

  Future<bool> shouldRetainSessionOnAppLaunch() async {
    if (await isKeepSignedInEnabled()) {
      return true;
    }
    if (await shouldRetainForOnboarding()) {
      return true;
    }
    return _hasEphemeralSessionThisLaunch;
  }

  Future<void> clearRememberedSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keepSignedInKey);
    await prefs.remove(_retainForOnboardingKey);
    _hasEphemeralSessionThisLaunch = false;
  }

  void clearEphemeralSessionMarker() {
    _hasEphemeralSessionThisLaunch = false;
  }

  Future<void> retainSessionForOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_retainForOnboardingKey, true);
  }

  Future<bool> shouldRetainForOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_retainForOnboardingKey) ?? false;
  }

  Future<void> clearOnboardingRetention() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_retainForOnboardingKey);
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mycondo/data/repositories/auth/auth_service.dart';
import 'package:mycondo/services/shared/session_preference_service.dart';
import 'package:mycondo/features/shared/widgets/session_timeout_dialog.dart';

class SessionTimerService {
  static final SessionTimerService _instance = SessionTimerService._internal();
  factory SessionTimerService() => _instance;
  SessionTimerService._internal();

  Timer? _timer;
  bool _isLoggingOut = false;
  final SessionPreferenceService _sessionPreferenceService =
      SessionPreferenceService();

  // Ichange lang guys if ano gd man, hindi me kamaan abi hehe
  // If want niyo itest, change minutes to seconds
  static const Duration _managerTimeoutDuration = Duration(minutes: 10);
  static const Duration _residentTimeoutDuration = Duration(minutes: 15);

  Duration _currentTimeoutDuration = _residentTimeoutDuration;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  void startTimer(String userRole) {
    _isLoggingOut = false;
    stopTimer();

    _currentTimeoutDuration = (userRole == 'manager')
        ? _managerTimeoutDuration
        : _residentTimeoutDuration;

    unawaited(_restartTimerIfEnabled());
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void resetTimer() {
    if (_timer == null || _isLoggingOut) return;

    unawaited(_restartTimerIfEnabled());
  }

  Duration timeoutDurationForRole(String userRole) {
    return userRole == 'manager'
        ? _managerTimeoutDuration
        : _residentTimeoutDuration;
  }

  bool get isTimerActive => _timer != null;

  Future<void> _restartTimerIfEnabled() async {
    final keepSignedIn = await _sessionPreferenceService
        .isKeepSignedInEnabled();
    if (keepSignedIn) {
      stopTimer();
      return;
    }

    stopTimer();
    _timer = Timer(_currentTimeoutDuration, _onTimeout);
  }

  Future<void> _onTimeout() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;

    stopTimer();

    try {
      await AuthService().signOut(clearRememberSessionPreference: false);
    } catch (e) {
      debugPrint("Auth error during timeout: $e");
    }

    final context = navigatorKey.currentContext;
    if (context == null) return;

    // Dismiss keyboard
    FocusManager.instance.primaryFocus?.unfocus();

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => SessionExpiredDialog(
        onConfirm: () {
          Navigator.of(
            dialogContext,
            rootNavigator: true,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        },
      ),
    );
  }
}

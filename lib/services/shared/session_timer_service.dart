import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mycondo/services/shared/presence_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mycondo/features/shared/widgets/session_timeout_dialog.dart';

class SessionTimerService {
  static final SessionTimerService _instance = SessionTimerService._internal();
  factory SessionTimerService() => _instance;
  SessionTimerService._internal();

  Timer? _timer;
  bool _isLoggingOut = false;

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

    _timer = Timer(_currentTimeoutDuration, _onTimeout);
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void resetTimer() {
    if (_timer == null || _isLoggingOut) return;

    stopTimer();
    _timer = Timer(_currentTimeoutDuration, _onTimeout);
  }

  Future<void> _onTimeout() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;

    stopTimer();

    try {
      try {
        await presenceService.stop();
      } catch (e) {
        debugPrint("Presence error during timeout logout: $e");
      }

      await Supabase.instance.client.auth.signOut();
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
          Navigator.of(dialogContext, rootNavigator: true)
            .pushNamedAndRemoveUntil('/login', (route) => false);
        },
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';

class SessionTimerService {
  static final SessionTimerService _instance = SessionTimerService._internal();
  factory SessionTimerService() => _instance;
  SessionTimerService._internal();

  Timer? _timer;
  // Ichange lang guys if ano gd man, hindi me kamaan abi hehe
  // If want niyo itest, change minutes to seconds
  static const Duration _managerTimeoutDuration = Duration(minutes: 10);
  static const Duration _residentTimeoutDuration = Duration(minutes: 15);

  Duration _currentTimeoutDuration = _managerTimeoutDuration;

  // Global key to allow navigation/dialogs without context
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  void startTimer(String userRole) {
    stopTimer();
    if (userRole == 'manager') {
      _currentTimeoutDuration = _managerTimeoutDuration;
    } else {
      _currentTimeoutDuration = _residentTimeoutDuration;
    }
    _timer = Timer(_currentTimeoutDuration, _onTimeout);
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void resetTimer() {
    if (_timer == null) return;
    stopTimer();
    _timer = Timer(_currentTimeoutDuration, _onTimeout);
  }

  void _onTimeout() {
    stopTimer();

    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Expired'),
        content: const Text('You have been logged out due to inactivity.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

extension AppSnackBars on BuildContext {
  /// Shows a SnackBar immediately by clearing any current/queued SnackBars first.
  ///
  /// Flutter's [ScaffoldMessengerState.showSnackBar] queues by default, which can
  /// delay status feedback. For status updates, we want the latest to replace
  /// the previous one right away.
  void showAppSnackBar(
    SnackBar snackBar, {
    bool replaceCurrent = true,
  }) {
    final messenger = ScaffoldMessenger.of(this);
    if (replaceCurrent) {
      messenger.clearSnackBars();
    }
    messenger.showSnackBar(snackBar);
  }
}


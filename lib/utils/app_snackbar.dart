import 'package:flutter/material.dart';
import 'package:mycondo/theme/app_theme.dart';

enum AppSnackTone {
  info,
  success,
  warning,
  error,
}

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

  void showAppMessage(
    String message, {
    AppSnackTone tone = AppSnackTone.info,
    bool replaceCurrent = true,
  }) {
    final messenger = ScaffoldMessenger.of(this);
    if (replaceCurrent) {
      messenger.clearSnackBars();
    }

    final statusColors = appStatusColors;
    final Color backgroundColor;
    final Color foregroundColor;

    switch (tone) {
      case AppSnackTone.success:
        backgroundColor = statusColors.success;
        foregroundColor = AppColors.pureWhite;
        break;
      case AppSnackTone.warning:
        backgroundColor = statusColors.warningStrong;
        foregroundColor = AppColors.black;
        break;
      case AppSnackTone.error:
        backgroundColor = statusColors.destructive;
        foregroundColor = AppColors.pureWhite;
        break;
      case AppSnackTone.info:
        backgroundColor = Theme.of(this).colorScheme.primary;
        foregroundColor = Theme.of(this).colorScheme.onPrimary;
        break;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: foregroundColor),
        ),
        backgroundColor: backgroundColor,
      ),
    );
  }
}

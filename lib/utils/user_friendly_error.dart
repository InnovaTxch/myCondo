import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class UserFriendlyError {
  static const String noInternetMessage =
      'No internet connection. Please check your network and try again.';

  static String messageFor(
    Object error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    if (error is SocketException || error is TimeoutException) {
      return noInternetMessage;
    }

    if (error is AuthException) {
      final authMessage = error.message;
      if (_looksLikeNetworkIssue(authMessage)) {
        return noInternetMessage;
      }
      return _friendlyFromText(authMessage, fallback: fallback);
    }

    final raw = error.toString();
    if (_looksLikeNetworkIssue(raw)) {
      return noInternetMessage;
    }

    return _friendlyFromText(raw, fallback: fallback);
  }

  static bool _looksLikeNetworkIssue(String text) {
    final normalized = text.toLowerCase();

    return normalized.contains('failed host lookup') ||
        normalized.contains('socketexception') ||
        normalized.contains('clientexception') ||
        normalized.contains('errno = 7') ||
        normalized.contains('no address associated with hostname') ||
        normalized.contains('network is unreachable') ||
        normalized.contains('connection refused') ||
        normalized.contains('connection reset');
  }

  static String _clean(String text) {
    if (text.startsWith('Exception: ')) {
      return text.substring('Exception: '.length).trim();
    }
    return text.trim();
  }

  static String _friendlyFromText(String text, {required String fallback}) {
    final cleaned = _clean(text);
    if (cleaned.isEmpty) return fallback;

    final normalized = cleaned.toLowerCase();

    if (normalized.contains('invalid login credentials') ||
        normalized.contains('invalid email or password')) {
      return 'Incorrect email or password. Please try again.';
    }

    if (normalized.contains('email not confirmed')) {
      return 'Please verify your email first, then sign in again.';
    }

    if (normalized.contains('already registered') ||
        normalized.contains('user already registered') ||
        normalized.contains('already in use')) {
      return 'This email is already in use. Try signing in instead.';
    }

    if (normalized.contains('weak password') ||
        normalized.contains('password should') ||
        normalized.contains('password must')) {
      return 'Password is too weak. Please choose a stronger password.';
    }

    if (normalized.contains('jwt') &&
        (normalized.contains('expired') || normalized.contains('invalid'))) {
      return 'Your session expired. Please sign in again.';
    }

    if (normalized.contains('permission denied') ||
        normalized.contains('not allowed') ||
        normalized.contains('not authorized') ||
        normalized.contains('forbidden') ||
        normalized.contains('row-level security')) {
      return 'You do not have permission to perform this action.';
    }

    if (normalized.contains('duplicate key') ||
        normalized.contains('already exists') ||
        normalized.contains('violates unique constraint')) {
      return 'This item already exists.';
    }

    if (normalized.contains('no rows') ||
        normalized.contains('not found') ||
        normalized.contains('resource not found')) {
      return 'We could not find what you are looking for.';
    }

    if (normalized.contains('timeout') ||
        normalized.contains('timed out') ||
        normalized.contains('deadline exceeded')) {
      return 'The request took too long. Please try again.';
    }

    if (_looksTechnical(cleaned)) {
      return fallback;
    }

    return cleaned;
  }

  static bool _looksTechnical(String text) {
    final normalized = text.toLowerCase();
    return normalized.contains('postgrestexception') ||
        normalized.contains('authretryablesfetchexception') ||
        normalized.contains('type \'null\' is not a subtype') ||
        normalized.startsWith('instance of');
  }
}

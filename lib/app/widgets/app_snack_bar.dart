import 'package:flutter/material.dart';

class AppSnackBar {
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  static const _duration = Duration(seconds: 2);

  static void success(String message) {
    _show(message, _SnackType.success);
  }

  static void error(String message) {
    _show(message, _SnackType.error);
  }

  static void info(String message) {
    _show(message, _SnackType.info);
  }

  static void _show(String message, _SnackType type) {
    final messenger = messengerKey.currentState;
    final context = messengerKey.currentContext;

    if (messenger == null || context == null) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final backgroundColor = switch (type) {
      _SnackType.success => colorScheme.tertiary,
      _SnackType.error => colorScheme.error,
      _SnackType.info => colorScheme.primary,
    };

    final foregroundColor = switch (type) {
      _SnackType.success => colorScheme.onTertiary,
      _SnackType.error => colorScheme.onError,
      _SnackType.info => colorScheme.onPrimary,
    };

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: _duration,
          backgroundColor: backgroundColor,
          content: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(color: foregroundColor),
          ),
        ),
      );
  }
}

enum _SnackType { success, error, info }

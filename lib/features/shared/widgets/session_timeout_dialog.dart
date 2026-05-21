import 'package:flutter/material.dart';

class SessionExpiredDialog extends StatelessWidget {
  const SessionExpiredDialog({
    super.key,
    required this.onConfirm,
  });

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Session Expired'),
      content: const Text('You have been logged out due to inactivity.'),
      actions: [
        TextButton(
          onPressed: onConfirm,
          child: const Text('Okay'),
        ),
      ],
    );
  }
}
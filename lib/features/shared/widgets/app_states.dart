import 'package:flutter/material.dart';

class AppLoadingState extends StatelessWidget {
  const AppLoadingState({
    super.key,
    this.color,
    this.strokeWidth,
    this.message,
  });

  final Color? color;
  final double? strokeWidth;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final indicator = CircularProgressIndicator(
      strokeWidth: strokeWidth ?? 4,
      color: color,
    );

    if ((message ?? '').trim().isEmpty) {
      return Center(child: indicator);
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          const SizedBox(height: 12),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF666666)),
          ),
        ],
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.card = true,
  });

  final IconData? icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool card;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 40, color: const Color(0xFF999999)),
          const SizedBox(height: 12),
        ],
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF777777)),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
        ],
      ],
    );

    if (!card) return Center(child: content);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: content,
    );
  }
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.message,
    this.details,
    this.onRetry,
  });

  final String message;
  final String? details;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    if (onRetry == null) {
      return Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFB3261E)),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton(
            onPressed: onRetry,
            child: Text(message),
          ),
          if ((details ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              details!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

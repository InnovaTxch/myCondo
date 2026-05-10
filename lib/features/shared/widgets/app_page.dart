import 'package:flutter/material.dart';

/// Standard page scaffold wrapper to reduce per-page boilerplate.
///
/// - Applies a consistent `Scaffold` + `SafeArea` structure
/// - Optionally wraps the body in a `RefreshIndicator`
class AppPageScaffold extends StatelessWidget {
  const AppPageScaffold({
    super.key,
    required this.body,
    this.backgroundColor,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.onRefresh,
    this.refreshIndicatorColor,
    this.safeArea,
  });

  final Color? backgroundColor;
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  final Future<void> Function()? onRefresh;
  final Color? refreshIndicatorColor;
  final bool? safeArea;

  @override
  Widget build(BuildContext context) {
    Widget content =
        (safeArea ?? true) ? SafeArea(child: body) : body;
    if (onRefresh != null) {
      content = RefreshIndicator(
        onRefresh: onRefresh!,
        color: refreshIndicatorColor,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: content,
    );
  }
}

/// A scrollable container that centers [child] while still allowing pull-to-refresh.
///
/// Useful for empty/error/loading states inside a [RefreshIndicator], where the
/// body must be scrollable to trigger the gesture.
class AppScrollableCentered extends StatelessWidget {
  const AppScrollableCentered({
    super.key,
    required this.child,
    this.height,
    this.heightFactor,
    this.padding,
  });

  final Widget child;
  final double? height;
  final double? heightFactor;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final resolvedHeight = height ??
        (heightFactor == null
            ? 360
            : MediaQuery.sizeOf(context).height * heightFactor!);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding ?? EdgeInsets.zero,
      children: [
        SizedBox(
          height: resolvedHeight,
          child: Center(child: child),
        ),
      ],
    );
  }
}

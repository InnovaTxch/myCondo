import 'package:flutter/material.dart';
import 'package:mycondo/theme/app_theme.dart';

class _BackArrowSymbol extends StatelessWidget {
  const _BackArrowSymbol();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '←',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.darkText,
        height: 1,
      ),
    );
  }
}

PreferredSizeWidget appPageAppBar({
  required BuildContext context,
  required String title,
  List<Widget>? actions,
  VoidCallback? onBackPressed,
  bool showBackButton = true,
}) {
  return AppBar(
    backgroundColor: AppColors.lightBlueBackground,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleSpacing: 0,
    automaticallyImplyLeading: false,
    leadingWidth: showBackButton ? 44 : 0,
    leading: showBackButton
        ? IconButton(
            onPressed: onBackPressed ?? () => Navigator.maybePop(context),
            icon: const _BackArrowSymbol(),
          )
        : null,
    title: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: AppColors.darkText,
        ),
      ),
    ),
    actions: actions,
  );
}

class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.onBackPressed,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(12, 10, 20, 8),
    this.preserveBackButtonSpaceWhenHidden = false,
  });

  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final bool preserveBackButtonSpaceWhenHidden;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (showBackButton)
            IconButton(
              onPressed: onBackPressed ?? () => Navigator.maybePop(context),
              icon: const _BackArrowSymbol(),
            )
          else if (preserveBackButtonSpaceWhenHidden)
            const SizedBox(width: 44),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.darkText,
              ),
            ),
          ),
          trailing ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}

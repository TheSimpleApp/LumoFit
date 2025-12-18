import 'package:flutter/material.dart';

/// Responsive action bar for detail screens.
///
/// - Wide layouts: render all actions in a single row.
/// - Narrow layouts: render primary action full-width, with secondary actions
///   side-by-side to avoid awkward label wrapping.
class DetailsActionBar extends StatelessWidget {
  final Widget leading;
  final Widget middle;
  final Widget primary;

  /// Optional breakpoint override. Defaults to 420 logical pixels.
  final double narrowBreakpoint;

  /// Gap between buttons.
  final double gap;

  const DetailsActionBar({
    super.key,
    required this.leading,
    required this.middle,
    required this.primary,
    this.narrowBreakpoint = 420,
    this.gap = 12,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < narrowBreakpoint;

        if (!isNarrow) {
          return Row(
            children: [
              Expanded(child: leading),
              SizedBox(width: gap),
              Expanded(child: middle),
              SizedBox(width: gap),
              Expanded(child: primary),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: leading),
                SizedBox(width: gap),
                Expanded(child: middle),
              ],
            ),
            SizedBox(height: gap),
            SizedBox(width: double.infinity, child: primary),
          ],
        );
      },
    );
  }
}

/// Helper to build non-wrapping label content inside Material buttons.
class ActionBarLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;

  const ActionBarLabel({
    super.key,
    required this.icon,
    required this.text,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ),
      ],
    );
  }
}



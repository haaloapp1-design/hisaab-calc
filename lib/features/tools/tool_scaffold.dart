import 'package:flutter/material.dart';

import '../../shared/widgets/blue_header.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_tokens.dart';

/// The layout every tool page shares (SPEC §6, screen `10-loan-emi.html`).
///
/// A blue header with the main result under it, then the white sheet that
/// holds the labelled inputs, a breakdown and the one primary action. The page
/// only passes widgets and strings; the tool's maths lives in `lib/core/tools/`
/// and the page keeps the inputs.
class ToolScaffold extends StatelessWidget {
  const ToolScaffold({
    super.key,
    required this.title,
    required this.resultLabel,
    required this.resultValue,
    this.resultCaption,
    this.onShare,
    this.children = const <Widget>[],
    this.actionLabel,
    this.onAction,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'actionLabel and onAction must be given together',
       );

  /// The centred 17 px header title, e.g. `Loan / EMI`.
  final String title;

  /// The small line above the result, e.g. `Monthly instalment`.
  final String resultLabel;

  /// The big result, already formatted by the page.
  final String resultValue;

  /// The small line under the result, e.g. `PKR for 60 months`.
  final String? resultCaption;

  /// Shows the header share action when set (screen 10's trailing glyph).
  final VoidCallback? onShare;

  /// The sheet content: labelled inputs and the breakdown card.
  final List<Widget> children;

  /// The primary action at the end of the sheet; hidden when null.
  final String? actionLabel;

  /// Runs [actionLabel]; both are required together.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Scaffold(
      backgroundColor: palette.primary,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            BlueHeader(
              title: title,
              onBack: () => Navigator.of(context).maybePop(),
              actionIcon: onShare == null ? null : Icons.ios_share_rounded,
              actionTooltip: onShare == null ? null : 'Share result',
              actionIconSize: AppSizes.toolShareIcon,
              onAction: onShare,
            ),
            _ToolResult(
              label: resultLabel,
              value: resultValue,
              caption: resultCaption,
            ),
            Expanded(
              child: _ToolSheet(action: _action, children: children),
            ),
          ],
        ),
      ),
    );
  }

  Widget? get _action {
    final String? label = actionLabel;
    final VoidCallback? callback = onAction;
    if (label == null || callback == null) {
      return null;
    }
    return _ToolAction(label: label, onTap: callback);
  }
}

/// The right-aligned label / result / caption block under the header.
class _ToolResult extends StatelessWidget {
  const _ToolResult({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Padding(
      key: const Key('tool-result'),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.toolResultPaddingSide,
        AppSizes.toolResultPaddingTop,
        AppSizes.toolResultPaddingSide,
        AppSizes.toolResultPaddingBottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.toolResultLabel.copyWith(
              color: palette.onPrimaryMuted,
            ),
          ),
          const SizedBox(height: AppSizes.toolResultGap),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value,
                key: const Key('tool-result-value'),
                maxLines: 1,
                style: AppTypography.toolResult.copyWith(
                  color: palette.onPrimary,
                ),
              ),
            ),
          ),
          if (caption != null) ...<Widget>[
            const SizedBox(height: AppSizes.toolResultGap),
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.toolResultLabel.copyWith(
                color: palette.onPrimaryMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The white sheet: handle, scrolling content and the primary action.
class _ToolSheet extends StatelessWidget {
  const _ToolSheet({required this.children, this.action});

  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);

    return Container(
      key: const Key('tool-sheet'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.toolSheetPaddingSide,
        AppSizes.toolSheetPaddingTop,
        AppSizes.toolSheetPaddingSide,
        AppSizes.toolSheetPaddingBottom,
      ),
      decoration: BoxDecoration(
        color: palette.sheet,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.sheet),
        ),
      ),
      child: Column(
        children: <Widget>[
          Container(
            key: const Key('tool-sheet-handle'),
            width: AppSizes.handleWidth,
            height: AppSizes.handleHeight,
            decoration: BoxDecoration(
              color: palette.primary,
              borderRadius: BorderRadius.circular(AppRadii.handle),
            ),
          ),
          const SizedBox(height: AppSizes.toolSheetGap),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  ...children,
                  if (action != null) ...<Widget>[
                    const SizedBox(height: AppSizes.toolSheetGap),
                    action!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The 52 px primary button at the end of the sheet.
class _ToolAction extends StatelessWidget {
  const _ToolAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    final BorderRadius radius = BorderRadius.circular(
      AppSizes.toolActionRadius,
    );

    return SizedBox(
      height: AppSizes.toolActionHeight,
      child: Semantics(
        button: true,
        label: label,
        onTap: onTap,
        excludeSemantics: true,
        child: Material(
          color: palette.primary,
          borderRadius: radius,
          child: InkWell(
            key: const Key('tool-action'),
            borderRadius: radius,
            onTap: onTap,
            child: Center(
              child: Text(
                label,
                style: AppTypography.toolAction.copyWith(
                  color: palette.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

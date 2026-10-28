import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/blue_header.dart';
import '../../theme/app_palette.dart';
import '../../theme/app_tokens.dart';
import '../settings/settings_controller.dart';
import '../settings/settings_format.dart';
import '../settings/settings_model.dart';
import 'currency_controller.dart';
import 'currency_readout.dart';
import 'currency_state.dart';
import 'widgets/currency_amount_field.dart';
import 'widgets/currency_picker_sheet.dart';
import 'widgets/currency_row_sheet.dart';
import 'widgets/currency_sheet.dart';
import 'widgets/currency_top.dart';

/// The currency converter (SPEC §5, screen `08-currency.html`).
///
/// The blue area holds the base pill, the typed amount and the rate status;
/// the white sheet lists every target with its value and rate line. A tap
/// changes a target, a long press opens the reorder/remove actions, and the
/// refresh icon or a pull refreshes the rates.
class CurrencyPage extends ConsumerStatefulWidget {
  const CurrencyPage({super.key});

  @override
  ConsumerState<CurrencyPage> createState() => _CurrencyPageState();
}

class _CurrencyPageState extends ConsumerState<CurrencyPage> {
  /// True when the provider was already loaded before this page opened, which
  /// means the controller's build will not refresh again on its own.
  bool _checkStaleOnOpen = false;

  @override
  void initState() {
    super.initState();
    _checkStaleOnOpen = ref.read(currencyProvider) is AsyncData<CurrencyState>;
    if (_checkStaleOnOpen) {
      // A revisit can find the cache older than 6 h while the provider is
      // alive; the first build already refreshes when there is no cache.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(currencyProvider.notifier).refreshIfStale();
        }
      });
    }
  }

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
              title: 'Currency',
              onBack: () => Navigator.of(context).maybePop(),
              actionIcon: Icons.refresh_rounded,
              actionTooltip: 'Refresh rates',
              onAction: _refresh,
            ),
            Expanded(
              child: ref
                  .watch(currencyProvider)
                  .when(
                    data: (CurrencyState state) => _buildBody(state),
                    loading: () => _LoadingSheet(palette: palette),
                    error: (Object error, StackTrace stack) => _ErrorSheet(
                      palette: palette,
                      message: 'Could not load currency settings.',
                      onRetry: () => ref.invalidate(currencyProvider),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(CurrencyState state) {
    final Settings settings = ref.watch(settingsProvider);
    final CurrencyReadout readout = CurrencyReadout(
      state: state,
      options: numberFormatFor(settings),
    );
    final CurrencyController controller = ref.read(currencyProvider.notifier);

    return Column(
      children: <Widget>[
        CurrencyTop(
          readout: readout,
          onPickBase: _pickBase,
          amountField: CurrencyAmountField(
            initialAmount: state.config.amount,
            options: readout.options,
            onChanged: controller.setAmount,
          ),
        ),
        Expanded(
          child: CurrencySheet(
            rows: readout.rows,
            onRowTap: _changeRow,
            onRowLongPress: _rowActions,
            onAdd: _addCurrency,
            onRefresh: _refresh,
          ),
        ),
      ],
    );
  }

  Future<void> _pickBase() async {
    final CurrencyState? state = ref.read(currencyProvider).value;
    if (state == null) {
      return;
    }
    final String? code = await showCurrencyPickerSheet(
      context,
      title: 'Base currency',
      selected: state.config.base,
    );
    if (code != null && mounted) {
      ref.read(currencyProvider.notifier).setBase(code);
    }
  }

  Future<void> _addCurrency() async {
    final CurrencyState? state = ref.read(currencyProvider).value;
    if (state == null) {
      return;
    }
    final String? code = await showCurrencyPickerSheet(
      context,
      title: 'Add currency',
      selected: '',
      excluded: <String>{state.config.base, ...state.config.targets},
    );
    if (code != null && mounted) {
      ref.read(currencyProvider.notifier).addCurrency(code);
    }
  }

  Future<void> _changeRow(CurrencyRowReadout row) async {
    final CurrencyState? state = ref.read(currencyProvider).value;
    if (state == null) {
      return;
    }
    final String oldCode = row.currency.code;
    final String? code = await showCurrencyPickerSheet(
      context,
      title: 'Change $oldCode',
      selected: oldCode,
      excluded: <String>{
        state.config.base,
        ...state.config.targets.where((String target) => target != oldCode),
      },
    );
    if (code != null && mounted) {
      ref.read(currencyProvider.notifier).replaceCurrency(oldCode, code);
    }
  }

  Future<void> _rowActions(CurrencyRowReadout row) async {
    final CurrencyState? state = ref.read(currencyProvider).value;
    if (state == null) {
      return;
    }
    final int index = state.config.targets.indexOf(row.currency.code);
    if (index == -1) {
      return;
    }
    final CurrencyRowAction? action = await showCurrencyRowSheet(
      context,
      currency: row.currency,
      canMoveUp: index > 0,
      canMoveDown: index < state.config.targets.length - 1,
    );
    if (!mounted || action == null) {
      return;
    }
    final CurrencyController controller = ref.read(currencyProvider.notifier);
    switch (action) {
      case CurrencyRowAction.change:
        await _changeRow(row);
        break;
      case CurrencyRowAction.moveUp:
        controller.moveCurrency(index, -1);
        break;
      case CurrencyRowAction.moveDown:
        controller.moveCurrency(index, 1);
        break;
      case CurrencyRowAction.remove:
        controller.removeCurrency(row.currency.code);
        _toast('${row.currency.code} removed');
        break;
    }
  }

  Future<void> _refresh() async {
    final bool ok = await ref.read(currencyProvider.notifier).refresh();
    if (!mounted || ok) {
      return;
    }
    _toast('Could not refresh rates');
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _LoadingSheet extends StatelessWidget {
  const _LoadingSheet({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.sheet,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.sheet),
        ),
      ),
      child: Center(
        child: CircularProgressIndicator(color: palette.primaryText),
      ),
    );
  }
}

class _ErrorSheet extends StatelessWidget {
  const _ErrorSheet({
    required this.palette,
    required this.message,
    required this.onRetry,
  });

  final AppPalette palette;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.sheet,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.sheet),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            message,
            style: AppTypography.body.copyWith(color: palette.inkMuted),
          ),
          const SizedBox(height: AppSizes.currencyTopGap),
          TextButton(
            key: const Key('currency-retry'),
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

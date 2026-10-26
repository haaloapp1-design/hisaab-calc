import 'dart:convert';

import 'currency_amount.dart';
import 'currency_catalog.dart';

/// The user's currency choices: base, target list and typed amount (SPEC §5).
///
/// It persists the ISO codes, not catalog objects, so a stored config still
/// opens after the catalog changes. Unknown or duplicate codes are dropped on
/// decode, and the base is never repeated in [targets].
final class CurrencyConfig {
  CurrencyConfig({
    String base = CurrencyCatalog.defaultBase,
    List<String> targets = CurrencyCatalog.defaultTargets,
    this.amount = defaultAmount,
  }) : base = _cleanBase(base),
       targets = _cleanTargets(base, targets);

  /// SPEC §5: the first visit shows PKR and these five currencies.
  static final CurrencyConfig defaults = CurrencyConfig(amount: defaultAmount);

  /// The amount screen 08 shows before the user types.
  static const CurrencyAmount defaultAmount = CurrencyAmount('10000');

  /// The currency every target is converted from.
  final String base;

  /// The target currencies, in the order the screen lists them.
  final List<String> targets;

  /// What the user typed in the amount field.
  final CurrencyAmount amount;

  bool get isEmpty => targets.isEmpty;

  bool containsTarget(String code) => targets.contains(code.toUpperCase());

  /// A copy with [code] as the base; the old base takes its place on top of
  /// the target list, which is what the swap in screen 08 does.
  CurrencyConfig withBase(String code) {
    final String upper = code.toUpperCase();
    if (!CurrencyCatalog.contains(upper) || upper == base) {
      return this;
    }
    return CurrencyConfig(
      base: upper,
      targets: <String>[
        base,
        ...targets.where((String target) => target != upper && target != base),
      ],
      amount: amount,
    );
  }

  /// A copy with [code] added at the end; the base and existing targets are
  /// ignored so a currency can never appear twice.
  CurrencyConfig addCurrency(String code) {
    final String upper = code.toUpperCase();
    if (!CurrencyCatalog.contains(upper) ||
        upper == base ||
        containsTarget(upper)) {
      return this;
    }
    return CurrencyConfig(
      base: base,
      targets: <String>[...targets, upper],
      amount: amount,
    );
  }

  /// A copy without [code]; removing an absent currency is a no-op.
  CurrencyConfig removeCurrency(String code) {
    final String upper = code.toUpperCase();
    if (!containsTarget(upper)) {
      return this;
    }
    return CurrencyConfig(
      base: base,
      targets: targets
          .where((String target) => target != upper)
          .toList(growable: false),
      amount: amount,
    );
  }

  /// A copy with [oldCode] replaced by [newCode] in place.
  ///
  /// The base, a currency already in the list or an unknown code leaves the
  /// config unchanged.
  CurrencyConfig replaceCurrency(String oldCode, String newCode) {
    final String oldUpper = oldCode.toUpperCase();
    final String newUpper = newCode.toUpperCase();
    if (!containsTarget(oldUpper) ||
        !CurrencyCatalog.contains(newUpper) ||
        newUpper == base ||
        (newUpper != oldUpper && containsTarget(newUpper))) {
      return this;
    }
    return CurrencyConfig(
      base: base,
      targets: <String>[
        for (final String target in targets)
          target == oldUpper ? newUpper : target,
      ],
      amount: amount,
    );
  }

  /// Moves the target at [index] by [delta] places, clamped to the list.
  CurrencyConfig moveCurrency(int index, int delta) {
    if (index < 0 || index >= targets.length || delta == 0) {
      return this;
    }
    final int destination = (index + delta).clamp(0, targets.length - 1);
    if (destination == index) {
      return this;
    }
    final List<String> next = targets.toList();
    final String moved = next.removeAt(index);
    next.insert(destination, moved);
    return CurrencyConfig(base: base, targets: next, amount: amount);
  }

  /// A copy with a new typed amount.
  CurrencyConfig withAmount(CurrencyAmount amount) =>
      CurrencyConfig(base: base, targets: targets, amount: amount);

  /// The stored JSON object.
  String encode() => jsonEncode(<String, Object?>{
    'base': base,
    'targets': targets,
    'amount': amount.source,
  });

  /// Reads the stored config; missing or corrupt data falls back to defaults.
  static CurrencyConfig decode(String? source) {
    if (source == null || source.isEmpty) {
      return defaults;
    }
    try {
      final Object? json = jsonDecode(source);
      if (json is! Map<String, Object?>) {
        return defaults;
      }
      final Object? storedBase = json['base'];
      final String base =
          storedBase is String && CurrencyCatalog.contains(storedBase)
          ? storedBase.toUpperCase()
          : CurrencyCatalog.defaultBase;
      final Object? storedTargets = json['targets'];
      final List<String> targets = <String>[];
      if (storedTargets is List<Object?>) {
        for (final Object? row in storedTargets) {
          if (row is! String) {
            continue;
          }
          final String code = row.toUpperCase();
          if (!CurrencyCatalog.contains(code) ||
              code == base ||
              targets.contains(code)) {
            continue;
          }
          targets.add(code);
        }
      } else {
        targets.addAll(
          CurrencyCatalog.defaultTargets.where((String code) => code != base),
        );
      }
      final Object? storedAmount = json['amount'];
      final CurrencyAmount amount = storedAmount is String
          ? CurrencyAmount.fromInput(storedAmount)
          : defaultAmount;
      return CurrencyConfig(base: base, targets: targets, amount: amount);
    } on FormatException {
      return defaults;
    }
  }

  static String _cleanBase(String base) => CurrencyCatalog.contains(base)
      ? base.toUpperCase()
      : CurrencyCatalog.defaultBase;

  static List<String> _cleanTargets(String base, List<String> targets) {
    final String cleanBase = _cleanBase(base);
    final List<String> clean = <String>[];
    for (final String code in targets) {
      final String upper = code.toUpperCase();
      if (!CurrencyCatalog.contains(upper) ||
          upper == cleanBase ||
          clean.contains(upper)) {
        continue;
      }
      clean.add(upper);
    }
    return List<String>.unmodifiable(clean);
  }

  @override
  bool operator ==(Object other) {
    if (other is! CurrencyConfig ||
        other.base != base ||
        other.amount != amount ||
        other.targets.length != targets.length) {
      return false;
    }
    for (int i = 0; i < targets.length; i++) {
      if (other.targets[i] != targets[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(base, Object.hashAll(targets), amount);

  @override
  String toString() => 'CurrencyConfig($base, $targets, $amount)';
}

import 'package:decimal/decimal.dart';

import '../../core/input/input_buffer.dart';

/// Everything the calculator screen renders (ARCHITECTURE "State").
///
/// Immutable: a key produces a new [CalcState]. [preview] is the live result
/// of the unfinished expression, or null when there is nothing to preview
/// (BUSINESS_LOGIC §5). It stays a [Decimal] so the display can format it with
/// the current settings and memory keys (`M+`/`M−`) can use the same value.
final class CalcState {
  CalcState({
    this.buffer = const InputBuffer.empty(),
    this.preview,
    Decimal? ans,
  }) : ans = ans ?? Decimal.zero;

  /// The tokens the user has typed so far.
  final InputBuffer buffer;

  /// §5 live preview: success only, never an error.
  final Decimal? preview;

  /// §9 the last `=` result, persisted between launches.
  final Decimal ans;

  bool get isEmpty => buffer.isEmpty;

  @override
  String toString() => 'CalcState($buffer, preview: $preview, ans: $ans)';
}

/// Edits the typed source string programmer mode evaluates (BUSINESS_LOGIC §11).
///
/// The source is what the keypad builds, e.g. `FF AND 0F`, `NOT 5`, `(2 + 3)`.
/// Every function returns the new string, so the controller stays a thin
/// dispatcher and the editing rules are unit-tested without a widget.
///
/// Numbers are written in the active base by the keypad; this class only
/// spaces, replaces and deletes, so it never needs to know the base.
abstract final class ProgSource {
  /// Operators a trailing edit can replace or delete, longest first so `NAND`
  /// is not read as `AND` and `AND` is not read as a hex `D`.
  static const List<String> _operators = <String>[
    'NAND',
    'AND',
    'XOR',
    'OR',
    'mod',
    'NOT',
    '<<',
    '>>',
    '+',
    '−',
    '-',
    '×',
    '*',
    '÷',
    '/',
  ];

  /// A trailing run of digits in any base (`[0-9A-Fa-f]`).
  static final RegExp _trailingNumber = RegExp(r'[0-9A-Fa-f]+$');

  /// Appends [digit] (`0`–`9`, `A`–`F`).
  ///
  /// A digit after `)` starts an explicit `×` because `ProgEngine` has no
  /// implicit multiplication, unlike the Basic/Scientific engine.
  static String appendDigit(String source, String digit) {
    final String trimmed = source.trimRight();
    if (trimmed.endsWith(')')) {
      return '$trimmed × $digit';
    }
    return '$source$digit';
  }

  /// Appends the binary [operator] with one space on each side.
  ///
  /// Tapping an operator twice replaces the previous one (§1.2), and `−` on an
  /// empty source becomes a unary sign so `±`-style entry works.
  static String appendOperator(String source, String operator) {
    String trimmed = source.trimRight();
    final int trailing = _trailingOperatorLength(trimmed);
    if (trailing > 0) {
      final String removed = trimmed.substring(trimmed.length - trailing);
      trimmed = trimmed.substring(0, trimmed.length - trailing).trimRight();
      // A unary sign is part of the operator before it, so `5 + −` + `×`
      // replaces both and leaves `5 ×`.
      if (removed == '−' && _isSignPosition(trimmed)) {
        final int previous = _trailingOperatorLength(trimmed);
        if (previous > 0) {
          trimmed = trimmed.substring(0, trimmed.length - previous).trimRight();
        }
      }
    }
    if (trimmed.isEmpty) {
      return operator == '−' ? '−' : '';
    }
    if (trimmed.endsWith('(')) {
      return '$trimmed$operator ';
    }
    return '$trimmed $operator ';
  }

  /// Appends the prefix `NOT`.
  ///
  /// After a value it inserts `× NOT` so `5 NOT 3` becomes the valid
  /// `5 × NOT 3`; otherwise it just writes `NOT` for the next operand.
  static String appendNot(String source) {
    final String trimmed = source.trimRight();
    if (trimmed.isEmpty || trimmed.endsWith('(')) {
      return '${trimmed}NOT ';
    }
    if (_trailingOperatorLength(trimmed) > 0) {
      return '$trimmed NOT ';
    }
    return '$trimmed × NOT ';
  }

  /// Appends `(`, adding the explicit `×` after a value.
  static String appendOpenParen(String source) {
    final String trimmed = source.trimRight();
    if (trimmed.isEmpty || trimmed.endsWith('(')) {
      return '$trimmed(';
    }
    if (_trailingOperatorLength(trimmed) > 0) {
      return '$trimmed (';
    }
    return '$trimmed × (';
  }

  /// Appends `)` when a bracket is open and the source ends with a value.
  static String appendCloseParen(String source) {
    final String trimmed = source.trimRight();
    if (_openParens(trimmed) == 0 || !_endsWithValue(trimmed)) {
      return source;
    }
    return '$trimmed)';
  }

  /// Removes the last character, or the whole trailing operator keyword.
  static String backspace(String source) {
    String trimmed = source.trimRight();
    if (trimmed.isEmpty) {
      return '';
    }
    final int trailing = _trailingOperatorLength(trimmed);
    trimmed = trailing > 0
        ? trimmed.substring(0, trimmed.length - trailing)
        : trimmed.substring(0, trimmed.length - 1);
    return trimmed.trimRight();
  }

  /// `±`: flips the sign of the last number or bracketed group.
  ///
  /// A `−` counts as a sign only when nothing value-like precedes it, so
  /// `5 − 3` becomes `5 − −3` instead of losing its subtraction.
  static String toggleSign(String source) {
    final String trimmed = source.trimRight();
    if (trimmed.isEmpty) {
      return '−';
    }
    if (_trailingOperatorLength(trimmed) > 0) {
      // A trailing `−` that is a sign is removed again; otherwise the new sign
      // goes after the operator (`5 + −`).
      if (trimmed.endsWith('−')) {
        final String before = trimmed
            .substring(0, trimmed.length - 1)
            .trimRight();
        if (_isSignPosition(before)) {
          return before;
        }
      }
      return '$trimmed −';
    }
    if (trimmed.endsWith('(')) {
      return '$trimmed−';
    }

    final RegExpMatch? number = _trailingNumber.firstMatch(trimmed);
    if (number != null) {
      final int start = number.start;
      if (start > 0 && trimmed[start - 1] == '−') {
        final String before = trimmed.substring(0, start - 1).trimRight();
        if (_isSignPosition(before)) {
          return '${trimmed.substring(0, start - 1)}${trimmed.substring(start)}';
        }
      }
      return '${trimmed.substring(0, start)}−${trimmed.substring(start)}';
    }

    if (trimmed.endsWith(')')) {
      final int open = _matchingOpenParen(trimmed);
      if (open < 0) {
        return source;
      }
      if (open > 0 && trimmed[open - 1] == '−') {
        final String before = trimmed.substring(0, open - 1).trimRight();
        if (_isSignPosition(before)) {
          return '${trimmed.substring(0, open - 1)}${trimmed.substring(open)}';
        }
      }
      return '${trimmed.substring(0, open)}−${trimmed.substring(open)}';
    }

    return source;
  }

  /// True when [before] ends where a unary sign may stand: at the start, after
  /// an operator or after `(`.
  static bool _isSignPosition(String before) =>
      before.isEmpty ||
      _trailingOperatorLength(before) > 0 ||
      before.endsWith('(');

  /// The length of the operator keyword/symbol at the end of [source], or 0.
  static int _trailingOperatorLength(String source) {
    for (final String operator in _operators) {
      if (source.length >= operator.length && source.endsWith(operator)) {
        return operator.length;
      }
    }
    return 0;
  }

  static bool _endsWithValue(String source) {
    if (source.isEmpty) {
      return false;
    }
    final String last = source[source.length - 1];
    return _isDigit(last) || last == ')';
  }

  static bool _isDigit(String char) {
    final int code = char.codeUnitAt(0);
    return (code >= 0x30 && code <= 0x39) ||
        (code >= 0x41 && code <= 0x46) ||
        (code >= 0x61 && code <= 0x66);
  }

  static int _openParens(String source) {
    int count = 0;
    for (int index = 0; index < source.length; index++) {
      if (source[index] == '(') {
        count++;
      } else if (source[index] == ')') {
        count--;
      }
    }
    return count;
  }

  /// The index of the `(` matching the `)` at the end of [source], or −1.
  static int _matchingOpenParen(String source) {
    int depth = 0;
    for (int index = source.length - 1; index >= 0; index--) {
      final String char = source[index];
      if (char == ')') {
        depth++;
      } else if (char == '(') {
        depth--;
        if (depth == 0) {
          return index;
        }
      }
    }
    return -1;
  }
}

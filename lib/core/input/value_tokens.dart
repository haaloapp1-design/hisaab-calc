import 'package:decimal/decimal.dart';

import '../engine/token.dart';

/// Tokens that insert a computed [Decimal] into the buffer (`Ans` and repeat
/// `=`, BUSINESS_LOGIC §5).
///
/// A negative value is wrapped as `(−n)` because [NumberToken] is always
/// unsigned (§1, §3).
List<Token> valueTokens(Decimal value) {
  if (value < Decimal.zero) {
    return <Token>[
      const LeftParenToken(),
      const UnaryToken(negative: true),
      NumberToken(value.abs().toString()),
      const RightParenToken(),
    ];
  }
  return <Token>[NumberToken(value.toString())];
}

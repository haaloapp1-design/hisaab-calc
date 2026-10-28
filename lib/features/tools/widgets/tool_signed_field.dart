import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/engine/formatter.dart';
import 'tool_field.dart';

/// A labelled decimal input that also accepts a negative sign.
///
/// [ToolAmountField] is built for money and drops the minus; an equation
/// coefficient needs it, so this field keeps a leading `-` and the Settings
/// decimal mark while still using the shared 50 px box. The page owns the
/// value; the field reports a [Decimal] on every edit.
class ToolSignedField extends StatefulWidget {
  const ToolSignedField({
    super.key,
    required this.label,
    required this.fieldKey,
    required this.initialValue,
    required this.options,
    required this.onChanged,
  });

  /// The 13 px label above the box, e.g. `a`.
  final String label;

  /// The key on the inner [TextField], used by the tests.
  final Key fieldKey;

  final Decimal initialValue;
  final NumberFormatOptions options;
  final ValueChanged<Decimal> onChanged;

  @override
  State<ToolSignedField> createState() => _ToolSignedFieldState();
}

class _ToolSignedFieldState extends State<ToolSignedField> {
  late final TextEditingController _controller = TextEditingController(
    text: _display(widget.initialValue, widget.options),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolField(
      label: widget.label,
      child: ToolFieldBox(
        child: ToolTextField(
          fieldKey: widget.fieldKey,
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(
            signed: true,
            decimal: true,
          ),
          inputFormatters: <TextInputFormatter>[
            _SignedDecimalFormatter(widget.options),
          ],
          onChanged: (String text) =>
              widget.onChanged(_parse(text, widget.options)),
        ),
      ),
    );
  }

  /// `-8`, or `-8,5` when the Settings decimal mark is a comma.
  static String _display(Decimal value, NumberFormatOptions options) {
    final String plain = value.toString();
    return options.decimalSeparator == '.'
        ? plain
        : plain.replaceAll('.', options.decimalSeparator);
  }

  /// An empty or half-typed field reads as zero, like the amount fields.
  static Decimal _parse(String text, NumberFormatOptions options) {
    String value = text.trim();
    if (value.isEmpty || value == '-') {
      return Decimal.zero;
    }
    if (options.decimalSeparator != '.') {
      value = value.replaceAll(options.decimalSeparator, '.');
    }
    return Decimal.tryParse(value) ?? Decimal.zero;
  }
}

/// Keeps one leading minus, one decimal mark and up to 12 digits.
class _SignedDecimalFormatter extends TextInputFormatter {
  const _SignedDecimalFormatter(this.options);

  final NumberFormatOptions options;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String text = newValue.text;
    final StringBuffer digits = StringBuffer();
    bool negative = false;
    bool hasMark = false;
    for (int i = 0; i < text.length; i++) {
      final String character = text[i];
      if (character == '-' && digits.isEmpty && !negative) {
        negative = true;
        continue;
      }
      if (character == '.' || character == options.decimalSeparator) {
        if (!hasMark) {
          if (digits.isEmpty) {
            digits.write('0');
          }
          digits.write('.');
          hasMark = true;
        }
        continue;
      }
      if (character.compareTo('0') < 0 || character.compareTo('9') > 0) {
        continue;
      }
      if (digits.length >= 12) {
        continue;
      }
      digits.write(character);
    }

    String result = digits.toString();
    if (result.isEmpty) {
      result = negative ? '-' : '0';
    } else if (negative) {
      result = '-$result';
    }
    final String shown = options.decimalSeparator == '.'
        ? result
        : result.replaceAll('.', options.decimalSeparator);
    return TextEditingValue(
      text: shown,
      selection: TextSelection.collapsed(offset: shown.length),
    );
  }
}

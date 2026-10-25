import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'app.dart';

void main() {
  // SPEC §3: the decimal separator follows the device locale.
  Intl.defaultLocale = Platform.localeName.replaceAll('-', '_');
  runApp(const ProviderScope(child: CalculatorApp()));
}

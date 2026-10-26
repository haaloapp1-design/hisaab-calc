/// One currency the converter knows by code and English name (SPEC §5).
final class Currency {
  const Currency(this.code, this.name);

  /// ISO 4217 code, e.g. `PKR`.
  final String code;

  /// The name shown under the code, e.g. `Pakistani rupee`.
  final String name;

  @override
  String toString() => 'Currency($code)';
}

/// The currencies the picker offers, in code order.
///
/// The API may return more codes; the app only lists currencies it has a name
/// for, which keeps the picker readable and the stored list valid.
abstract final class CurrencyCatalog {
  /// SPEC §5: the currency screen opens on PKR.
  static const String defaultBase = 'PKR';

  /// SPEC §5: the five target currencies shown on a first visit.
  static const List<String> defaultTargets = <String>[
    'USD',
    'EUR',
    'GBP',
    'AED',
    'SAR',
  ];

  static const List<Currency> all = <Currency>[
    Currency('AED', 'UAE dirham'),
    Currency('AFN', 'Afghan afghani'),
    Currency('ARS', 'Argentine peso'),
    Currency('AUD', 'Australian dollar'),
    Currency('BDT', 'Bangladeshi taka'),
    Currency('BHD', 'Bahraini dinar'),
    Currency('BRL', 'Brazilian real'),
    Currency('CAD', 'Canadian dollar'),
    Currency('CHF', 'Swiss franc'),
    Currency('CLP', 'Chilean peso'),
    Currency('CNY', 'Chinese yuan'),
    Currency('COP', 'Colombian peso'),
    Currency('CZK', 'Czech koruna'),
    Currency('DKK', 'Danish krone'),
    Currency('DZD', 'Algerian dinar'),
    Currency('EGP', 'Egyptian pound'),
    Currency('EUR', 'Euro'),
    Currency('GBP', 'British pound'),
    Currency('GHS', 'Ghanaian cedi'),
    Currency('HKD', 'Hong Kong dollar'),
    Currency('HUF', 'Hungarian forint'),
    Currency('IDR', 'Indonesian rupiah'),
    Currency('ILS', 'Israeli new shekel'),
    Currency('INR', 'Indian rupee'),
    Currency('IQD', 'Iraqi dinar'),
    Currency('IRR', 'Iranian rial'),
    Currency('JOD', 'Jordanian dinar'),
    Currency('JPY', 'Japanese yen'),
    Currency('KES', 'Kenyan shilling'),
    Currency('KRW', 'South Korean won'),
    Currency('KWD', 'Kuwaiti dinar'),
    Currency('LKR', 'Sri Lankan rupee'),
    Currency('MAD', 'Moroccan dirham'),
    Currency('MUR', 'Mauritian rupee'),
    Currency('MXN', 'Mexican peso'),
    Currency('MYR', 'Malaysian ringgit'),
    Currency('NGN', 'Nigerian naira'),
    Currency('NOK', 'Norwegian krone'),
    Currency('NPR', 'Nepalese rupee'),
    Currency('NZD', 'New Zealand dollar'),
    Currency('OMR', 'Omani rial'),
    Currency('PEN', 'Peruvian sol'),
    Currency('PHP', 'Philippine peso'),
    Currency('PKR', 'Pakistani rupee'),
    Currency('PLN', 'Polish zloty'),
    Currency('QAR', 'Qatari riyal'),
    Currency('RON', 'Romanian leu'),
    Currency('RUB', 'Russian ruble'),
    Currency('SAR', 'Saudi riyal'),
    Currency('SEK', 'Swedish krona'),
    Currency('SGD', 'Singapore dollar'),
    Currency('THB', 'Thai baht'),
    Currency('TND', 'Tunisian dinar'),
    Currency('TRY', 'Turkish lira'),
    Currency('TWD', 'New Taiwan dollar'),
    Currency('UAH', 'Ukrainian hryvnia'),
    Currency('USD', 'US dollar'),
    Currency('VND', 'Vietnamese dong'),
    Currency('ZAR', 'South African rand'),
  ];

  /// The currency with [code], case-insensitively, or null.
  static Currency? byCode(String code) {
    final String upper = code.toUpperCase();
    for (final Currency currency in all) {
      if (currency.code == upper) {
        return currency;
      }
    }
    return null;
  }

  /// The display name of [code], or the code itself when unknown.
  static String nameOf(String code) => byCode(code)?.name ?? code;

  /// True when [code] is a currency the app can show.
  static bool contains(String code) => byCode(code) != null;

  /// Currencies whose code or name contains [query], case-insensitively.
  static List<Currency> search(String query) {
    final String text = query.trim().toUpperCase();
    if (text.isEmpty) {
      return all;
    }
    return <Currency>[
      for (final Currency currency in all)
        if (currency.code.contains(text) ||
            currency.name.toUpperCase().contains(text))
          currency,
    ];
  }
}

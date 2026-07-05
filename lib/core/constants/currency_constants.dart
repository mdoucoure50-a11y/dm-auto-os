/// Supported currencies for the cashbook module.
enum AppCurrency {
  xaf('XAF', 'FCFA', 'fr_CM', 0, 'Franc CFA'),
  usd('USD', r'$', 'en_US', 2, 'US Dollar'),
  eur('EUR', '€', 'fr_FR', 2, 'Euro');

  const AppCurrency(
    this.code,
    this.symbol,
    this.locale,
    this.decimalDigits,
    this.name,
  );

  final String code;
  final String symbol;
  final String locale;
  final int decimalDigits;
  final String name;

  static AppCurrency fromCode(String code) {
    return AppCurrency.values.firstWhere(
      (currency) => currency.code == code.toUpperCase(),
      orElse: () => AppCurrency.xaf,
    );
  }

  bool get isDefault => this == AppCurrency.xaf;
}

/// Currency configuration — XAF is the default ledger currency.
abstract final class CurrencyConstants {
  static const AppCurrency defaultCurrency = AppCurrency.xaf;

  /// Default exchange rates to XAF (user can override per entry).
  static const Map<AppCurrency, double> defaultRatesToXaf = {
    AppCurrency.xaf: 1.0,
    AppCurrency.usd: 600.0,
    AppCurrency.eur: 655.0,
  };

  static double defaultRateFor(AppCurrency currency) =>
      defaultRatesToXaf[currency] ?? 1.0;

  static String get code => defaultCurrency.code;
  static String get name => defaultCurrency.name;
  static String get symbol => defaultCurrency.symbol;
  static String get locale => defaultCurrency.locale;
  static int get decimalDigits => defaultCurrency.decimalDigits;

  /// Converts an amount in [currency] to XAF using [exchangeRate].
  static int toXaf({
    required int amountOriginal,
    required AppCurrency currency,
    required double exchangeRate,
  }) {
    if (currency.isDefault) return amountOriginal;
    return (amountOriginal * exchangeRate).round();
  }
}

import 'package:intl/intl.dart';

import '../constants/currency_constants.dart';

/// Formats monetary values for XAF, USD, and EUR.
abstract final class CurrencyFormatter {
  static String format(
    int amount, {
    AppCurrency currency = AppCurrency.xaf,
  }) {
    return _formatterFor(currency).format(
      currency.decimalDigits == 0 ? amount : amount / 100,
    );
  }

  static String formatXaf(int amountXaf) => format(amountXaf);

  static String formatWithCode(
    int amount, {
    required AppCurrency currency,
  }) {
    return '${format(amount, currency: currency)} ${currency.code}';
  }

  static String formatCompact(int amountXaf) {
    if (amountXaf >= 1000000) {
      return '${(amountXaf / 1000000).toStringAsFixed(1)}M ${AppCurrency.xaf.symbol}';
    }
    if (amountXaf >= 1000) {
      return '${(amountXaf / 1000).toStringAsFixed(0)}K ${AppCurrency.xaf.symbol}';
    }
    return formatXaf(amountXaf);
  }

  static int? parse(String value, {AppCurrency currency = AppCurrency.xaf}) {
    final cleaned = value.replaceAll(RegExp(r'[^\d.,]'), '');
    if (cleaned.isEmpty) return null;

    if (currency.decimalDigits == 0) {
      final digits = cleaned.replaceAll(RegExp(r'[^\d]'), '');
      if (digits.isEmpty) return null;
      return int.tryParse(digits);
    }

    final normalized = cleaned.replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    if (parsed == null) return null;
    return (parsed * 100).round();
  }

  static NumberFormat _formatterFor(AppCurrency currency) {
    return NumberFormat.currency(
      locale: currency.locale,
      symbol: currency.symbol,
      decimalDigits: currency.decimalDigits,
    );
  }
}

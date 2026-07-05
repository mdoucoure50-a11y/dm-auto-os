import 'package:intl/intl.dart';

import '../constants/currency_constants.dart';

/// Formats monetary values in XAF (Central African CFA franc).
abstract final class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: CurrencyConstants.locale,
    symbol: CurrencyConstants.symbol,
    decimalDigits: CurrencyConstants.decimalDigits,
  );

  static String format(int amountXaf) => _formatter.format(amountXaf);

  static String formatCompact(int amountXaf) {
    if (amountXaf >= 1000000) {
      return '${(amountXaf / 1000000).toStringAsFixed(1)}M ${CurrencyConstants.symbol}';
    }
    if (amountXaf >= 1000) {
      return '${(amountXaf / 1000).toStringAsFixed(0)}K ${CurrencyConstants.symbol}';
    }
    return format(amountXaf);
  }

  static int? parse(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned);
  }
}

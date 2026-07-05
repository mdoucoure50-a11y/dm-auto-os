import 'package:dm_auto_os/core/constants/currency_constants.dart';
import 'package:dm_auto_os/core/utils/currency_formatter.dart';
import 'package:dm_auto_os/data/models/cashbook_models.dart';
import 'package:dm_auto_os/domain/entities/cashbook.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurrencyConstants', () {
    test('XAF is default currency', () {
      expect(CurrencyConstants.defaultCurrency, AppCurrency.xaf);
    });

    test('converts USD to XAF using exchange rate', () {
      expect(
        CurrencyConstants.toXaf(
          amountOriginal: 100,
          currency: AppCurrency.usd,
          exchangeRate: 600,
        ),
        60000,
      );
    });

    test('XAF conversion returns original amount', () {
      expect(
        CurrencyConstants.toXaf(
          amountOriginal: 150000,
          currency: AppCurrency.xaf,
          exchangeRate: 1,
        ),
        150000,
      );
    });
  });

  group('CurrencyFormatter', () {
    test('formats XAF amounts', () {
      final formatted = CurrencyFormatter.formatXaf(150000);
      expect(formatted, contains('FCFA'));
    });

    test('formats USD amounts with symbol', () {
      final formatted = CurrencyFormatter.format(200, currency: AppCurrency.usd);
      expect(formatted, contains(r'$'));
    });

    test('parses XAF integer amounts', () {
      expect(CurrencyFormatter.parse('150000'), 150000);
    });
  });

  group('CashbookEntryInput', () {
    test('computes amountXaf for EUR entry', () {
      final input = CashbookEntryInput(
        entryType: CashbookEntryType.income,
        categoryCode: 'deposit',
        amountOriginal: 100,
        currency: AppCurrency.eur,
        exchangeRate: 655,
        entryDate: _fixedDate,
      );

      expect(input.amountXaf, 65500);
    });

    test('uses category label as default description', () {
      final input = CashbookEntryInput(
        entryType: CashbookEntryType.expense,
        categoryCode: 'fuel',
        amountOriginal: 35000,
        currency: AppCurrency.xaf,
        exchangeRate: 1,
        entryDate: _fixedDate,
      );

      expect(input.resolvedDescription, 'Fuel');
    });
  });

  group('CashbookEntryModel', () {
    test('maps JSON to entity with multi-currency fields', () {
      final model = CashbookEntryModel.fromJson({
        'id': 'entry-1',
        'cashbook_sequence': 1,
        'entry_date': '2026-07-05',
        'transaction_type': 'income',
        'category': 'deposit',
        'currency_code': 'USD',
        'amount_original': 200,
        'exchange_rate': 600,
        'amount_xaf': 120000,
        'signed_amount_xaf': 120000,
        'running_balance_xaf': 120000,
        'description': 'Deposit',
        'notes': 'Paid in USD',
        'customer_name': 'Jean Mbarga',
        'attachment_count': 1,
      });

      final entity = model.toEntity();
      expect(entity.currency, AppCurrency.usd);
      expect(entity.amountOriginal, 200);
      expect(entity.amountXaf, 120000);
      expect(entity.customerName, 'Jean Mbarga');
      expect(entity.hasAttachment, isTrue);
    });
  });

  group('CashbookFilter', () {
    test('copyWith clears optional filters', () {
      const filter = CashbookFilter(
        entryType: CashbookEntryType.income,
        categoryCode: 'deposit',
        currency: AppCurrency.usd,
      );

      final cleared = filter.copyWith(clearEntryType: true, clearCurrency: true);
      expect(cleared.entryType, isNull);
      expect(cleared.categoryCode, 'deposit');
      expect(cleared.currency, isNull);
    });
  });
}

final _fixedDate = DateTime(2026, 7, 5);

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/currency_constants.dart';
import '../../../../domain/entities/cashbook.dart';
import '../../../../providers/cashbook_provider.dart';

class CashbookFilterSheet extends ConsumerStatefulWidget {
  const CashbookFilterSheet({super.key});

  @override
  ConsumerState<CashbookFilterSheet> createState() =>
      _CashbookFilterSheetState();
}

class _CashbookFilterSheetState extends ConsumerState<CashbookFilterSheet> {
  late CashbookEntryType? _entryType;
  late String? _categoryCode;
  late String? _customerId;
  late String? _vehicleId;
  late AppCurrency? _currency;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _summaryDate;
  bool _initialized = false;

  void _loadFilter(CashbookFilter filter) {
    _entryType = filter.entryType;
    _categoryCode = filter.categoryCode;
    _customerId = filter.customerId;
    _vehicleId = filter.vehicleId;
    _currency = filter.currency;
    _startDate = filter.startDate;
    _endDate = filter.endDate;
    _summaryDate = filter.summaryDate;
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      _loadFilter(ref.read(cashbookFilterProvider));
      _initialized = true;
    }

    final customers = ref.watch(customerOptionsProvider);
    final vehicles = ref.watch(vehicleOptionsProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Filter Cashbook', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<CashbookEntryType?>(
              value: _entryType,
              decoration: const InputDecoration(
                labelText: 'Entry type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(
                  value: CashbookEntryType.income,
                  child: Text('Income'),
                ),
                DropdownMenuItem(
                  value: CashbookEntryType.expense,
                  child: Text('Expense'),
                ),
              ],
              onChanged: (value) => setState(() {
                _entryType = value;
                _categoryCode = null;
              }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              value: _categoryCode,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All categories')),
                ..._categoriesForType(_entryType).map(
                  (category) => DropdownMenuItem(
                    value: category.code,
                    child: Text(category.label),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _categoryCode = value),
            ),
            const SizedBox(height: 12),
            customers.when(
              data: (options) => DropdownButtonFormField<String?>(
                value: _customerId,
                decoration: const InputDecoration(
                  labelText: 'Customer',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All customers')),
                  ...options.map(
                    (customer) => DropdownMenuItem(
                      value: customer.id,
                      child: Text(customer.fullName),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _customerId = value),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),
            vehicles.when(
              data: (options) => DropdownButtonFormField<String?>(
                value: _vehicleId,
                decoration: const InputDecoration(
                  labelText: 'Vehicle',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All vehicles')),
                  ...options.map(
                    (vehicle) => DropdownMenuItem(
                      value: vehicle.id,
                      child: Text('${vehicle.label} (${vehicle.licensePlate})'),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _vehicleId = value),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AppCurrency?>(
              value: _currency,
              decoration: const InputDecoration(
                labelText: 'Currency',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All currencies')),
                ...AppCurrency.values.map(
                  (currency) => DropdownMenuItem(
                    value: currency,
                    child: Text('${currency.code} — ${currency.name}'),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _currency = value),
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'Daily summary date',
              date: _summaryDate,
              onPick: (date) => setState(() => _summaryDate = date),
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'Period start',
              date: _startDate,
              onPick: (date) => setState(() => _startDate = date),
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'Period end',
              date: _endDate,
              onPick: (date) => setState(() => _endDate = date),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    ref.read(cashbookFilterProvider.notifier).state =
                        CashbookFilter(summaryDate: DateTime.now());
                    Navigator.pop(context);
                  },
                  child: const Text('Reset'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    ref.read(cashbookFilterProvider.notifier).state =
                        CashbookFilter(
                      entryType: _entryType,
                      categoryCode: _categoryCode,
                      customerId: _customerId,
                      vehicleId: _vehicleId,
                      currency: _currency,
                      startDate: _startDate,
                      endDate: _endDate,
                      summaryDate: _summaryDate,
                      searchQuery: ref.read(cashbookFilterProvider).searchQuery,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<({String code, String label})> _categoriesForType(
    CashbookEntryType? type,
  ) {
    if (type == CashbookEntryType.income) {
      return IncomeCategory.values
          .map((category) => (code: category.code, label: category.label))
          .toList();
    }
    if (type == CashbookEntryType.expense) {
      return ExpenseCategory.values
          .map((category) => (code: category.code, label: category.label))
          .toList();
    }

    return [
      ...IncomeCategory.values.map(
        (category) => (code: category.code, label: category.label),
      ),
      ...ExpenseCategory.values.map(
        (category) => (code: category.code, label: category.label),
      ),
    ];
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onPick,
  });

  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          date != null ? DateFormat.yMMMd().format(date!) : 'Select date',
        ),
      ),
    );
  }
}

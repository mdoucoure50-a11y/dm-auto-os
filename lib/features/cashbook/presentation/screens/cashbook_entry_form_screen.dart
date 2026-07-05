import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/currency_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../domain/entities/cashbook.dart';
import '../../../../providers/cashbook_provider.dart';

class CashbookEntryFormScreen extends ConsumerStatefulWidget {
  const CashbookEntryFormScreen({
    super.key,
    required this.entryType,
    this.entryId,
  });

  final CashbookEntryType entryType;
  final String? entryId;

  @override
  ConsumerState<CashbookEntryFormScreen> createState() =>
      _CashbookEntryFormScreenState();
}

class _CashbookEntryFormScreenState
    extends ConsumerState<CashbookEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _exchangeRateController = TextEditingController();

  late CashbookEntryType _entryType;
  late String _categoryCode;
  AppCurrency _currency = AppCurrency.xaf;
  DateTime _entryDate = DateTime.now();
  String? _customerId;
  String? _vehicleId;
  Uint8List? _attachmentBytes;
  String? _attachmentFileName;
  String? _attachmentMimeType;
  bool _loadingEntry = false;
  bool _entryLoaded = false;

  @override
  void initState() {
    super.initState();
    _entryType = widget.entryType;
    _categoryCode = _entryType == CashbookEntryType.income
        ? IncomeCategory.rentalPayment.code
        : ExpenseCategory.fuel.code;
    _exchangeRateController.text =
        CurrencyConstants.defaultRateFor(_currency).toString();

    if (widget.entryId != null) {
      _loadingEntry = true;
      Future.microtask(_loadExistingEntry);
    }
  }

  Future<void> _loadExistingEntry() async {
    final entry = await ref
        .read(cashbookRepositoryProvider)
        .fetchEntryById(widget.entryId!);

    if (!mounted) return;

    if (entry == null) {
      setState(() => _loadingEntry = false);
      return;
    }

    setState(() {
      _loadingEntry = false;
      _entryLoaded = true;
      _entryType = entry.entryType;
      _categoryCode = entry.categoryCode;
      _currency = entry.currency;
      _entryDate = entry.entryDate;
      _customerId = entry.customerId;
      _vehicleId = entry.vehicleId;
      _amountController.text = entry.amountOriginal.toString();
      _notesController.text = entry.notes ?? '';
      _exchangeRateController.text = entry.exchangeRate.toString();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _exchangeRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerOptionsProvider);
    final vehiclesAsync = ref.watch(vehicleOptionsProvider);
    final saveState = ref.watch(cashbookControllerProvider);

    if (_loadingEntry) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.entryId != null && !_entryLoaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Entry')),
        body: const Center(child: Text('Entry not found')),
      );
    }

    final isIncome = _entryType == CashbookEntryType.income;
    final title = widget.entryId == null
        ? (isIncome ? 'Add Income' : 'Add Expense')
        : (isIncome ? 'Edit Income' : 'Edit Expense');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.entryId == null)
              SegmentedButton<CashbookEntryType>(
                segments: const [
                  ButtonSegment(
                    value: CashbookEntryType.income,
                    label: Text('Income'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                  ButtonSegment(
                    value: CashbookEntryType.expense,
                    label: Text('Expense'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                ],
                selected: {_entryType},
                onSelectionChanged: (selection) {
                  setState(() {
                    _entryType = selection.first;
                    _categoryCode = _entryType == CashbookEntryType.income
                        ? IncomeCategory.rentalPayment.code
                        : ExpenseCategory.fuel.code;
                    _customerId = null;
                    _vehicleId = null;
                  });
                },
              ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _categoryCode,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categoryItems(),
              onChanged: (value) {
                if (value != null) setState(() => _categoryCode = value);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount (${_currency.code})',
                border: const OutlineInputBorder(),
                prefixText: '${_currency.symbol} ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                final amount = CurrencyFormatter.parse(
                  value ?? '',
                  currency: _currency,
                );
                if (amount == null || amount <= 0) {
                  return 'Enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AppCurrency>(
              value: _currency,
              decoration: const InputDecoration(
                labelText: 'Currency',
                border: OutlineInputBorder(),
              ),
              items: AppCurrency.values
                  .map(
                    (currency) => DropdownMenuItem(
                      value: currency,
                      child: Text('${currency.code} — ${currency.name}'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _currency = value;
                  _exchangeRateController.text =
                      CurrencyConstants.defaultRateFor(value).toString();
                });
              },
            ),
            if (!_currency.isDefault) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _exchangeRateController,
                decoration: const InputDecoration(
                  labelText: 'Exchange rate to XAF',
                  border: OutlineInputBorder(),
                  helperText: 'Ledger balance is stored in XAF',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  final rate = double.tryParse(value ?? '');
                  if (rate == null || rate <= 0) {
                    return 'Enter a valid exchange rate';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(DateFormat.yMMMd().format(_entryDate)),
              ),
            ),
            const SizedBox(height: 12),
            if (isIncome)
              customersAsync.when(
                data: (customers) => DropdownButtonFormField<String?>(
                  value: _customerId,
                  decoration: const InputDecoration(
                    labelText: 'Customer',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('No customer'),
                    ),
                    ...customers.map(
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
              )
            else
              vehiclesAsync.when(
                data: (vehicles) => DropdownButtonFormField<String?>(
                  value: _vehicleId,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('No vehicle'),
                    ),
                    ...vehicles.map(
                      (vehicle) => DropdownMenuItem(
                        value: vehicle.id,
                        child: Text(
                          '${vehicle.label} (${vehicle.licensePlate})',
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _vehicleId = value),
                  validator: (value) {
                    if (!isIncome && value == null) {
                      return 'Vehicle is required for expenses';
                    }
                    return null;
                  },
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickAttachment,
              icon: const Icon(Icons.attach_file),
              label: Text(
                _attachmentFileName ?? 'Add attachment (optional)',
              ),
            ),
            if (_attachmentFileName != null) ...[
              const SizedBox(height: 8),
              Text(
                'Selected: $_attachmentFileName',
                style: context.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: saveState.isLoading ? null : _save,
              child: saveState.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.entryId == null ? 'Save Entry' : 'Update Entry'),
            ),
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _categoryItems() {
    if (_entryType == CashbookEntryType.income) {
      return IncomeCategory.values
          .map(
            (category) => DropdownMenuItem(
              value: category.code,
              child: Text(category.label),
            ),
          )
          .toList();
    }

    return ExpenseCategory.values
        .map(
          (category) => DropdownMenuItem(
            value: category.code,
            child: Text(category.label),
          ),
        )
        .toList();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _entryDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _entryDate = picked);
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'pdf',
        'jpg',
        'jpeg',
        'png',
        'webp',
        'doc',
        'docx',
      ],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() {
      _attachmentBytes = file.bytes;
      _attachmentFileName = file.name;
      _attachmentMimeType = _mimeTypeForExtension(file.extension);
    });
  }

  String? _mimeTypeForExtension(String? extension) {
    return switch (extension?.toLowerCase()) {
      'pdf' => 'application/pdf',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      _ => null,
    };
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = CurrencyFormatter.parse(
      _amountController.text,
      currency: _currency,
    );
    if (amount == null) return;

    final exchangeRate = _currency.isDefault
        ? 1.0
        : double.parse(_exchangeRateController.text);

    final input = CashbookEntryInput(
      entryType: _entryType,
      categoryCode: _categoryCode,
      amountOriginal: amount,
      currency: _currency,
      exchangeRate: exchangeRate,
      entryDate: _entryDate,
      customerId: _entryType == CashbookEntryType.income ? _customerId : null,
      vehicleId: _entryType == CashbookEntryType.expense ? _vehicleId : null,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    await ref.read(cashbookControllerProvider.notifier).saveEntry(
          entryId: widget.entryId,
          input: input,
          attachmentBytes: _attachmentBytes,
          attachmentFileName: _attachmentFileName,
          attachmentMimeType: _attachmentMimeType,
        );

    final state = ref.read(cashbookControllerProvider);
    if (!mounted) return;

    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error.toString())),
      );
      return;
    }

    context.pop();
  }
}

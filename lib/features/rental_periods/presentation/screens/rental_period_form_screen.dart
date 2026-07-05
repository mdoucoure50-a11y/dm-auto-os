import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/entities/rental_period.dart';
import '../../../../providers/cashbook_provider.dart';
import '../../../../providers/rental_period_provider.dart';

class RentalPeriodFormScreen extends ConsumerStatefulWidget {
  const RentalPeriodFormScreen({super.key});

  @override
  ConsumerState<RentalPeriodFormScreen> createState() =>
      _RentalPeriodFormScreenState();
}

class _RentalPeriodFormScreenState
    extends ConsumerState<RentalPeriodFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 6));
  String? _customerId;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerOptionsProvider);
    final saveState = ref.watch(rentalPeriodControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Rental Period'),
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
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Period name',
                border: OutlineInputBorder(),
                helperText: 'e.g. July 2026 — Week 1',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a period name';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start date'),
              subtitle: Text(_formatDate(_startDate)),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today_outlined),
                onPressed: () => _pickDate(isStart: true),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('End date'),
              subtitle: Text(_formatDate(_endDate)),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today_outlined),
                onPressed: () => _pickDate(isStart: false),
              ),
            ),
            const SizedBox(height: 12),
            customersAsync.when(
              data: (customers) => DropdownButtonFormField<String?>(
                value: _customerId,
                decoration: const InputDecoration(
                  labelText: 'Customer (optional)',
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
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: saveState.isLoading ? null : _submit,
              icon: const Icon(Icons.lock_open),
              label: saveState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Open Period'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be on or after start date')),
      );
      return;
    }

    final input = OpenRentalPeriodInput(
      name: _nameController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      customerId: _customerId,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    try {
      final period =
          await ref.read(rentalPeriodControllerProvider.notifier).openPeriod(input);
      if (!mounted) return;
      context.go('/rental-periods/${period.id}');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

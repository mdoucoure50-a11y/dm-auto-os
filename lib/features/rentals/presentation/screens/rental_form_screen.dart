import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/entities/mission.dart';
import '../../../../providers/cashbook_provider.dart';
import '../../../../providers/rental_provider.dart';

class RentalFormScreen extends ConsumerStatefulWidget {
  const RentalFormScreen({super.key});

  @override
  ConsumerState<RentalFormScreen> createState() => _RentalFormScreenState();
}

class _RentalFormScreenState extends ConsumerState<RentalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dailyRateController = TextEditingController(text: '25000');
  final _notesController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 6));
  String? _customerId;
  String? _vehicleId;
  String? _missionId;

  @override
  void dispose() {
    _dailyRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerOptionsProvider);
    final vehiclesAsync = ref.watch(vehicleOptionsProvider);
    final missionsAsync = ref.watch(missionsProvider);
    final saveState = ref.watch(rentalControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Rental'),
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
            customersAsync.when(
              data: (customers) => DropdownButtonFormField<String>(
                value: _customerId,
                decoration: const InputDecoration(
                  labelText: 'Customer',
                  border: OutlineInputBorder(),
                ),
                items: customers
                    .map(
                      (customer) => DropdownMenuItem(
                        value: customer.id,
                        child: Text(customer.fullName),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _customerId = value),
                validator: (value) =>
                    value == null ? 'Select a customer' : null,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),
            vehiclesAsync.when(
              data: (vehicles) => DropdownButtonFormField<String>(
                value: _vehicleId,
                decoration: const InputDecoration(
                  labelText: 'Vehicle',
                  border: OutlineInputBorder(),
                ),
                items: vehicles
                    .map(
                      (vehicle) => DropdownMenuItem(
                        value: vehicle.id,
                        child: Text(
                          '${vehicle.label} (${vehicle.licensePlate})',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _vehicleId = value),
                validator: (value) =>
                    value == null ? 'Select a vehicle' : null,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),
            missionsAsync.when(
              data: (missions) => DropdownButtonFormField<String?>(
                value: _missionId,
                decoration: const InputDecoration(
                  labelText: 'Mission (optional)',
                  border: OutlineInputBorder(),
                  helperText:
                      'e.g. African Union Summit, COMILOG Contract, Airport Transfer',
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('No mission'),
                  ),
                  ...missions.map(
                    (mission) => DropdownMenuItem(
                      value: mission.id,
                      child: Text(mission.name),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _missionId = value),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
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
            TextFormField(
              controller: _dailyRateController,
              decoration: const InputDecoration(
                labelText: 'Daily rate (XAF)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                final rate = int.tryParse(value ?? '');
                if (rate == null || rate <= 0) return 'Enter a valid daily rate';
                return null;
              },
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
            FilledButton(
              onPressed: saveState.isLoading ? null : _submit,
              child: saveState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Rental'),
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

    final dailyRate = int.parse(_dailyRateController.text);
    final input = RentalAgreementInput(
      vehicleId: _vehicleId!,
      customerId: _customerId!,
      startDate: _startDate,
      endDate: _endDate,
      dailyRateXaf: dailyRate,
      missionId: _missionId,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    try {
      await ref.read(rentalControllerProvider.notifier).createRental(input);
      if (!mounted) return;
      context.pop();
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

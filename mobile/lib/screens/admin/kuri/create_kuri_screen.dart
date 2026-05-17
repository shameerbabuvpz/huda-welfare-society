import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../providers/kuri_provider.dart';

class CreateKuriScreen extends StatefulWidget {
  const CreateKuriScreen({super.key});

  @override
  State<CreateKuriScreen> createState() => _CreateKuriScreenState();
}

class _CreateKuriScreenState extends State<CreateKuriScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _membersController = TextEditingController();
  final _amountController = TextEditingController();
  final _durationController = TextEditingController();
  DateTime? _startDate;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _membersController.dispose();
    _amountController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _startDate == null) {
      if (_startDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(AppTheme.errorSnackBar('Select a start date'));
      }
      return;
    }
    setState(() => _saving = true);

    final data = {
      'name': _nameController.text.trim(),
      'total_members': int.parse(_membersController.text),
      'monthly_amount': double.parse(_amountController.text),
      'duration_months': int.parse(_durationController.text),
      'start_date': _startDate!.toIso8601String().split('T')[0],
    };

    final success = await context.read<KuriProvider>().createGroup(data);
    setState(() => _saving = false);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(AppTheme.successSnackBar('Kuri group created'));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.errorSnackBar(context.read<KuriProvider>().error ?? 'Failed'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Kuri Group')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Group Name *'),
                validator: (v) => v != null && v.isNotEmpty ? null : 'Required',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _membersController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Total Members *'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final n = int.tryParse(v);
                  return n != null && n >= 2 ? null : 'Min 2 members';
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Monthly Amount (₹) *'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  return double.tryParse(v) != null ? null : 'Enter valid amount';
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Duration (months) *'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  return int.tryParse(v) != null ? null : 'Enter valid number';
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_startDate == null ? 'Select Start Date *' : 'Start: ${_startDate!.toIso8601String().split('T')[0]}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
                tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving ? const CircularProgressIndicator(strokeWidth: 2) : const Text('Create Group'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../providers/ayalkoottam_provider.dart';

class AddAyalkoottamScreen extends StatefulWidget {
  const AddAyalkoottamScreen({super.key});

  @override
  State<AddAyalkoottamScreen> createState() => _AddAyalkoottamScreenState();
}

class _AddAyalkoottamScreenState extends State<AddAyalkoottamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _placeController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final data = {
      'name': _nameController.text.trim(),
      if (_placeController.text.isNotEmpty) 'place': _placeController.text.trim(),
    };

    final success = await context.read<AyalkoottamProvider>().create(data);
    setState(() => _saving = false);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(AppTheme.successSnackBar('Ayalkoottam added'));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.errorSnackBar(context.read<AyalkoottamProvider>().error ?? 'Failed'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Ayalkoottam')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name *', prefixIcon: Icon(Icons.groups_2)),
                validator: (v) => v != null && v.isNotEmpty ? null : 'Required',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _placeController,
                decoration: const InputDecoration(labelText: 'Place', prefixIcon: Icon(Icons.location_on)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving ? const CircularProgressIndicator(strokeWidth: 2) : const Text('Add Ayalkoottam'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

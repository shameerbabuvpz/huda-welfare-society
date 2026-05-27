import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../providers/asset_provider.dart';
import '../../../models/asset.dart';

class AddAssetScreen extends StatefulWidget {
  final Asset? assetToEdit;
  const AddAssetScreen({super.key, this.assetToEdit});

  @override
  State<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends State<AddAssetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _categoryController = TextEditingController();
  final _costController = TextEditingController();
  DateTime? _purchaseDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.assetToEdit != null) {
      final asset = widget.assetToEdit!;
      _nameController.text = asset.name;
      _descController.text = asset.description ?? '';
      _categoryController.text = asset.category ?? '';
      _costController.text = asset.cost?.toString() ?? '';
      if (asset.purchaseDate != null) {
        _purchaseDate = DateTime.tryParse(asset.purchaseDate!);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _purchaseDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final data = {
      'name': _nameController.text.trim(),
      if (_descController.text.isNotEmpty) 'description': _descController.text.trim(),
      if (_categoryController.text.isNotEmpty) 'category': _categoryController.text.trim(),
      if (_purchaseDate != null) 'purchase_date': DateFormat('yyyy-MM-dd').format(_purchaseDate!),
      if (_costController.text.isNotEmpty) 'cost': double.tryParse(_costController.text.trim()),
    };

    bool success;
    if (widget.assetToEdit != null) {
      success = await context.read<AssetProvider>().updateAsset(widget.assetToEdit!.id, data);
    } else {
      success = await context.read<AssetProvider>().createAsset(data);
    }

    setState(() => _saving = false);

    if (!mounted) return;
    if (success) {
      final message = widget.assetToEdit != null ? 'Item updated' : 'Item added';
      ScaffoldMessenger.of(context).showSnackBar(AppTheme.successSnackBar(message));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.errorSnackBar(context.read<AssetProvider>().error ?? 'Failed'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.assetToEdit != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Item' : 'Add Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Item Name *', prefixIcon: Icon(Icons.inventory_2)),
                validator: (v) => v != null && v.isNotEmpty ? null : 'Required',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category)),
              ),
              const SizedBox(height: 16),
              // Purchase Date
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Purchase Date', prefixIcon: Icon(Icons.calendar_today)),
                  child: Text(
                    _purchaseDate != null ? DateFormat('dd/MM/yyyy').format(_purchaseDate!) : 'Select date',
                    style: TextStyle(color: _purchaseDate != null ? Colors.black : Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Cost (optional)
              TextFormField(
                controller: _costController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                decoration: const InputDecoration(labelText: 'Approximate Cost (optional)', prefixIcon: Icon(Icons.currency_rupee), prefixText: '₹ '),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving ? const CupertinoActivityIndicator() : Text(isEditing ? 'Update Item' : 'Add Item'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

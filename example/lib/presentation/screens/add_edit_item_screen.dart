import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/inventory_item.dart';
import '../providers/business_providers.dart';

class AddEditItemScreen extends ConsumerStatefulWidget {
  final InventoryItem? item;

  const AddEditItemScreen({super.key, this.item});

  @override
  ConsumerState<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends ConsumerState<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _categoryController;
  late TextEditingController _thresholdController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name);
    _descriptionController = TextEditingController(
      text: widget.item?.description,
    );
    _priceController = TextEditingController(
      text: widget.item?.price.toString() ?? '',
    );
    _quantityController = TextEditingController(
      text: widget.item?.quantity.toString() ?? '',
    );
    _categoryController = TextEditingController(
      text: widget.item?.category ?? 'General',
    );
    _thresholdController = TextEditingController(
      text: widget.item?.lowStockThreshold.toString() ?? '5',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _categoryController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (_formKey.currentState!.validate()) {
      final item = InventoryItem(
        id: widget.item?.id,
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.tryParse(_priceController.text) ?? 0.0,
        quantity: int.tryParse(_quantityController.text) ?? 0,
        category: _categoryController.text,
        lowStockThreshold: int.tryParse(_thresholdController.text) ?? 5,
        createdAt: widget.item?.createdAt,
      );

      if (widget.item == null) {
        await ref.read(inventoryProvider.notifier).addItem(item);
      } else {
        await ref.read(inventoryProvider.notifier).updateItem(item);
      }

      if (mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text(
          widget.item == null ? 'New Item' : 'Edit Item',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _saveItem,
            child: Text(
              'SAVE',
              style: GoogleFonts.poppins(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Product Basics'),
              const SizedBox(height: 20),
              _buildGlassField(
                controller: _nameController,
                label: 'Item Name',
                icon: Icons.inventory_2_outlined,
                hint: 'e.g. Premium Coffee Beans',
              ),
              const SizedBox(height: 16),
              _buildGlassField(
                controller: _descriptionController,
                label: 'Description',
                icon: Icons.description_outlined,
                hint: 'Describe your product...',
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              _buildSectionTitle('Inventory & Pricing'),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildGlassField(
                      controller: _priceController,
                      label: 'Unit Price',
                      icon: Icons.attach_money,
                      hint: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildGlassField(
                      controller: _quantityController,
                      label: 'Stock Level',
                      icon: Icons.reorder_outlined,
                      hint: '0',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildGlassField(
                      controller: _categoryController,
                      label: 'Category',
                      icon: Icons.category_outlined,
                      hint: 'General',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildGlassField(
                      controller: _thresholdController,
                      label: 'Low Alert',
                      icon: Icons.warning_amber_outlined,
                      hint: '5',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: Colors.green.withValues(alpha: 0.4),
                  ),
                  child: Text(
                    widget.item == null ? 'Add to Inventory' : 'Update Item',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.poppins(
        color: Colors.grey[500],
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildGlassField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: GoogleFonts.poppins(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: Colors.grey[400],
            fontSize: 14,
          ),
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.greenAccent, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }
}

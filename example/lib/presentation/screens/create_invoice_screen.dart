import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/client.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/invoice.dart';
import '../providers/business_providers.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  final InvoiceType type;
  const CreateInvoiceScreen({super.key, required this.type});

  @override
  ConsumerState<CreateInvoiceScreen> createState() =>
      _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  Client? _selectedClient;
  final List<InvoiceItem> _items = [];
  final _notesController = TextEditingController();
  final _taxRateController = TextEditingController(text: '0');

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.total);
  double get _taxRate => double.tryParse(_taxRateController.text) ?? 0;
  double get _total => _subtotal + (_subtotal * (_taxRate / 100));

  @override
  void dispose() {
    _notesController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }

  void _addItem(InventoryItem product) {
    setState(() {
      _items.add(
        InvoiceItem(
          description: product.name,
          quantity: 1,
          unitPrice: product.price,
        ),
      );
    });
  }

  Future<void> _saveInvoice() async {
    if (_selectedClient == null || _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a client and add at least one item'),
        ),
      );
      return;
    }

    final invoice = Invoice(
      invoiceNumber: 'INV-${DateTime.now().millisecondsSinceEpoch}',
      clientId: _selectedClient!.id,
      clientName: _selectedClient!.name,
      items: _items,
      subtotal: _subtotal,
      taxRate: _taxRate / 100,
      notes: _notesController.text,
      status: InvoiceStatus.draft,
      type: widget.type,
    );

    await ref.read(invoicesProvider.notifier).addInvoice(invoice);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);
    final inventoryAsync = ref.watch(inventoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text(
          widget.type == InvoiceType.invoice
              ? 'Create Invoice'
              : 'Create Quotation',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.greenAccent),
            onPressed: _saveInvoice,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Client Information'),
            const SizedBox(height: 12),
            clientsAsync.when(
              data: (clients) => _buildClientSelector(clients),
              loading: () => const CircularProgressIndicator(),
              error: (_, _) => const Text('Error loading clients'),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle(
              widget.type == InvoiceType.invoice
                  ? 'Invoice Items'
                  : 'Quotation Items',
            ),
            const SizedBox(height: 12),
            ..._items.asMap().entries.map(
              (entry) => _buildItemTile(entry.key, entry.value),
            ),
            const SizedBox(height: 12),
            inventoryAsync.when(
              data: (items) => _buildAddItemButton(items),
              loading: () => const SizedBox(),
              error: (_, _) => const SizedBox(),
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('Summary'),
            const SizedBox(height: 12),
            _buildSummaryTable(),
            const SizedBox(height: 32),
            _buildSectionTitle('Additional Notes'),
            const SizedBox(height: 12),
            _buildGlassTextField(_notesController, 'Notes', maxLines: 3),
          ],
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

  Widget _buildClientSelector(List<Client> clients) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Client>(
          dropdownColor: const Color(0xFF2A2A2A),
          value: _selectedClient,
          hint: Text(
            'Select Client',
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
          isExpanded: true,
          items: clients
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(
                    c.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
              .toList(),
          onChanged: (val) => setState(() => _selectedClient = val),
        ),
      ),
    );
  }

  Widget _buildItemTile(int index, InvoiceItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Unit Price: \$${item.unitPrice.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 16, color: Colors.white),
                  onPressed: () {
                    if (item.quantity > 1) {
                      setState(() {
                        _items[index] = item.copyWith(
                          quantity: item.quantity - 1,
                        );
                      });
                    }
                  },
                ),
                Text(
                  item.quantity.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 16, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _items[index] = item.copyWith(
                        quantity: item.quantity + 1,
                      );
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '\$${item.total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
              size: 20,
            ),
            onPressed: () => setState(() => _items.removeAt(index)),
          ),
        ],
      ),
    );
  }

  Widget _buildAddItemButton(List<InventoryItem> products) {
    return OutlinedButton.icon(
      onPressed: () => _showProductPicker(products),
      icon: const Icon(Icons.add),
      label: const Text('Add Product'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.orange,
        side: const BorderSide(color: Colors.orange),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showProductPicker(List<InventoryItem> products) {
    String pickerSearch = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setPickerState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Select Product',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: const Icon(Icons.search, color: Colors.orange),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => setPickerState(() => pickerSearch = val),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: products
                      .where(
                        (p) => p.name.toLowerCase().contains(
                          pickerSearch.toLowerCase(),
                        ),
                      )
                      .length,
                  itemBuilder: (context, i) {
                    final filteredProducts = products
                        .where(
                          (p) => p.name.toLowerCase().contains(
                            pickerSearch.toLowerCase(),
                          ),
                        )
                        .toList();
                    final prod = filteredProducts[i];
                    return ListTile(
                      title: Text(
                        prod.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Stock: ${prod.quantity} | \$${prod.price}',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      onTap: () {
                        _addItem(prod);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', '\$${_subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tax (%)', style: TextStyle(color: Colors.grey[400])),
              SizedBox(
                width: 60,
                child: TextField(
                  controller: _taxRateController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.grey),
          _buildSummaryRow(
            'Total',
            '\$${_total.toStringAsFixed(2)}',
            isBold: true,
            color: Colors.greenAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isBold ? Colors.white : Colors.grey[400],
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 18 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}

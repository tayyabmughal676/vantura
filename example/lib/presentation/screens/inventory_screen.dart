import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/business_providers.dart';
import '../../domain/entities/inventory_item.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryProvider);
    final lowStockAsync = ref.watch(lowStockCountProvider);
    final totalItemsAsync = ref.watch(totalInventoryCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text(
          'Inventory',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: inventoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (inventory) => SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildSearchBar(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: totalItemsAsync.when(
                      data: (count) => _buildStatCard(
                        'Total Items',
                        count.toString(),
                        Colors.blue,
                      ),
                      loading: () =>
                          _buildStatCard('Total Items', '...', Colors.blue),
                      error: (error, stack) =>
                          _buildStatCard('Total Items', 'Error', Colors.blue),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: lowStockAsync.when(
                      data: (count) => _buildStatCard(
                        'Low Stock',
                        count.toString(),
                        Colors.orange,
                      ),
                      loading: () =>
                          _buildStatCard('Low Stock', '...', Colors.orange),
                      error: (error, stack) =>
                          _buildStatCard('Low Stock', 'Error', Colors.orange),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildInventoryList(
                inventory
                    .where(
                      (item) =>
                          item.name.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ||
                          item.category.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddScreen,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _confirmDeleteItem(InventoryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Delete Item',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete ${item.name}?',
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && item.id != null) {
      await ref.read(inventoryProvider.notifier).deleteItem(item.id!);
    }
  }

  void _showAddScreen() {
    context.push('/inventory/add');
  }

  void _showEditScreen(InventoryItem item) {
    context.push('/inventory/edit', extra: item);
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.poppins(color: Colors.white),
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
          prefixIcon: const Icon(Icons.search, color: Colors.greenAccent),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.green, Colors.lightGreenAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory, color: Colors.white, size: 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inventory Management',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Track your products and stock levels',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryList(List<InventoryItem> inventory) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inventory Items (${inventory.length})',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        if (inventory.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Center(
              child: Text(
                'No inventory items yet.\nTap the + button to add your first item.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: inventory.length,
            itemBuilder: (context, index) {
              final item = inventory[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: item.isLowStock
                        ? Colors.orange.withValues(alpha: 0.3)
                        : Colors.grey.withValues(alpha: 0.2),
                  ),
                ),
                child: InkWell(
                  onTap: () => _showEditScreen(item),
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: item.isLowStock
                              ? Colors.orange.withValues(alpha: 0.1)
                              : Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: item.isLowStock
                                ? Colors.orange.withValues(alpha: 0.3)
                                : Colors.green.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(
                          item.isLowStock
                              ? Icons.warning_amber_rounded
                              : Icons.inventory_2_rounded,
                          color: item.isLowStock ? Colors.orange : Colors.green,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  '\$${item.price.toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.greenAccent,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.description,
                              style: GoogleFonts.poppins(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: item.isLowStock
                                        ? Colors.orange.withValues(alpha: 0.1)
                                        : Colors.blueAccent.withValues(
                                            alpha: 0.1,
                                          ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${item.quantity} in stock',
                                    style: GoogleFonts.poppins(
                                      color: item.isLowStock
                                          ? Colors.orange
                                          : Colors.blueAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  item.category,
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        color: const Color(0xFF2A2A2A),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditScreen(item);
                          } else if (value == 'delete') {
                            _confirmDeleteItem(item);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18, color: Colors.green),
                                SizedBox(width: 8),
                                Text(
                                  'Edit',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete,
                                  size: 18,
                                  color: Colors.redAccent,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

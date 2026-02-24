import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/business_providers.dart';
import '../../domain/entities/invoice.dart';

class InvoicingScreen extends ConsumerStatefulWidget {
  const InvoicingScreen({super.key});

  @override
  ConsumerState<InvoicingScreen> createState() => _InvoicingScreenState();
}

class _InvoicingScreenState extends ConsumerState<InvoicingScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoicesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text(
          'Invoicing & Quotes',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSearchBar(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 24),
            invoicesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (invoices) => _buildRecentInvoices(
                invoices
                    .where(
                      (i) =>
                          i.clientName.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ||
                          i.invoiceNumber.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/invoicing/create?type=invoice'),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _updateStatus(int id, InvoiceStatus status) async {
    await ref.read(invoicesProvider.notifier).updateInvoiceStatus(id, status);
  }

  Future<void> _deleteInvoice(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Delete Invoice',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete this invoice?',
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

    if (confirmed == true) {
      await ref.read(invoicesProvider.notifier).deleteInvoice(id);
    }
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
          hintText: 'Search invoices or clients...',
          hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
          prefixIcon: const Icon(Icons.search, color: Colors.orange),
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
          colors: [Colors.orange, Colors.deepOrangeAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt, color: Colors.white, size: 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invoice & Quote Management',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Create and manage invoices and quotations',
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

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => context.push('/invoicing/create?type=invoice'),
            child: _buildActionButton(
              'New Invoice',
              Icons.receipt_long,
              Colors.blue,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () => context.push('/invoicing/create?type=quote'),
            child: _buildActionButton(
              'New Quote',
              Icons.description,
              Colors.green,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentInvoices(List<Invoice> invoices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Invoices & Quotes (${invoices.length})',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        if (invoices.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Center(
              child: Text(
                'No invoices or quotes yet.\nTap the + button to create your first one.',
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
            itemCount: invoices.length,
            itemBuilder: (context, index) {
              final invoice = invoices[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStatusColor(
                      invoice.status,
                    ).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          invoice.status,
                        ).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getStatusIcon(invoice.status),
                        color: _getStatusColor(invoice.status),
                        size: 24,
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
                                  invoice.type == InvoiceType.invoice
                                      ? invoice.invoiceNumber
                                      : 'QUOTE-${invoice.invoiceNumber.split('-').last}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                '\$${invoice.total.toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                  color: Colors.greenAccent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            invoice.clientName,
                            style: GoogleFonts.poppins(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    invoice.status,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  (invoice.type == InvoiceType.quote &&
                                          invoice.status == InvoiceStatus.draft)
                                      ? 'QUOTATION'
                                      : invoice.status.name.toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    color: _getStatusColor(invoice.status),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Due: ${_formatDate(invoice.dueDate)}',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[400],
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
                        if (value == 'paid' && invoice.id != null) {
                          _updateStatus(invoice.id!, InvoiceStatus.paid);
                        } else if (value == 'accepted' && invoice.id != null) {
                          _updateStatus(invoice.id!, InvoiceStatus.accepted);
                        } else if (value == 'rejected' && invoice.id != null) {
                          _updateStatus(invoice.id!, InvoiceStatus.rejected);
                        } else if (value == 'convert' && invoice.id != null) {
                          ref
                              .read(invoicesProvider.notifier)
                              .convertToInvoice(invoice.id!);
                        } else if (value == 'delete' && invoice.id != null) {
                          _deleteInvoice(invoice.id!);
                        }
                      },
                      itemBuilder: (context) => [
                        if (invoice.type == InvoiceType.invoice &&
                            invoice.status != InvoiceStatus.paid)
                          const PopupMenuItem(
                            value: 'paid',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 18,
                                  color: Colors.green,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Mark Paid',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        if (invoice.type == InvoiceType.quote &&
                            invoice.status == InvoiceStatus.draft) ...[
                          const PopupMenuItem(
                            value: 'accepted',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.thumb_up,
                                  size: 18,
                                  color: Colors.greenAccent,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Accept Quote',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'rejected',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.thumb_down,
                                  size: 18,
                                  color: Colors.redAccent,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Reject Quote',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (invoice.type == InvoiceType.quote &&
                            invoice.status == InvoiceStatus.accepted)
                          const PopupMenuItem(
                            value: 'convert',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.receipt,
                                  size: 18,
                                  color: Colors.blueAccent,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Convert to Invoice',
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
              );
            },
          ),
      ],
    );
  }

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return Colors.grey;
      case InvoiceStatus.sent:
        return Colors.blue;
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.overdue:
        return Colors.red;
      case InvoiceStatus.cancelled:
        return Colors.orange;
      case InvoiceStatus.accepted:
        return Colors.tealAccent;
      case InvoiceStatus.rejected:
        return Colors.redAccent;
    }
  }

  IconData _getStatusIcon(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return Icons.drafts;
      case InvoiceStatus.sent:
        return Icons.send;
      case InvoiceStatus.paid:
        return Icons.check_circle;
      case InvoiceStatus.overdue:
        return Icons.warning;
      case InvoiceStatus.cancelled:
        return Icons.cancel;
      case InvoiceStatus.accepted:
        return Icons.thumb_up;
      case InvoiceStatus.rejected:
        return Icons.thumb_down;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.month}/${date.day}/${date.year}';
  }
}

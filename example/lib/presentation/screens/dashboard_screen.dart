import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/floating_chat_button.dart';
import '../providers/business_providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);
    final inventoryAsync = ref.watch(inventoryProvider);
    final invoicesAsync = ref.watch(invoicesProvider);
    final ledgerAsync = ref.watch(ledgerEntriesProvider);
    final lowStockAsync = ref.watch(lowStockCountProvider);
    final incomeAsync = ref.watch(totalIncomeProvider);
    final expensesAsync = ref.watch(totalExpensesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text(
          'Vantura Business Suite',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to Vantura',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your business with AI-powered tools',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 32),
                _buildAnalyticsSummary(
                  clientsAsync,
                  inventoryAsync,
                  invoicesAsync,
                  ledgerAsync,
                  lowStockAsync,
                  incomeAsync,
                  expensesAsync,
                ),
                const SizedBox(height: 24),
                _buildFeatureGrid(context),
              ],
            ),
          ),
          const FloatingChatButton(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSummary(
    AsyncValue<List> clientsAsync,
    AsyncValue<List> inventoryAsync,
    AsyncValue<List> invoicesAsync,
    AsyncValue<List> ledgerAsync,
    AsyncValue<int> lowStockAsync,
    AsyncValue<double> incomeAsync,
    AsyncValue<double> expensesAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Business Overview',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: clientsAsync.when(
                data: (clients) => _buildAnalyticsCard(
                  'Total Clients',
                  clients.length.toString(),
                  Icons.people,
                  Colors.blue,
                ),
                loading: () => _buildAnalyticsCard(
                  'Total Clients',
                  '...',
                  Icons.people,
                  Colors.blue,
                ),
                error: (error, stack) => _buildAnalyticsCard(
                  'Total Clients',
                  'Error',
                  Icons.people,
                  Colors.blue,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: inventoryAsync.when(
                data: (inventory) => _buildAnalyticsCard(
                  'Inventory Items',
                  inventory.length.toString(),
                  Icons.inventory,
                  Colors.green,
                ),
                loading: () => _buildAnalyticsCard(
                  'Inventory Items',
                  '...',
                  Icons.inventory,
                  Colors.green,
                ),
                error: (error, stack) => _buildAnalyticsCard(
                  'Inventory Items',
                  'Error',
                  Icons.inventory,
                  Colors.green,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: invoicesAsync.when(
                data: (invoices) => _buildAnalyticsCard(
                  'Total Invoices',
                  invoices.length.toString(),
                  Icons.receipt,
                  Colors.orange,
                ),
                loading: () => _buildAnalyticsCard(
                  'Total Invoices',
                  '...',
                  Icons.receipt,
                  Colors.orange,
                ),
                error: (error, stack) => _buildAnalyticsCard(
                  'Total Invoices',
                  'Error',
                  Icons.receipt,
                  Colors.orange,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ledgerAsync.when(
                data: (entries) => _buildAnalyticsCard(
                  'Transactions',
                  entries.length.toString(),
                  Icons.account_balance,
                  Colors.purple,
                ),
                loading: () => _buildAnalyticsCard(
                  'Transactions',
                  '...',
                  Icons.account_balance,
                  Colors.purple,
                ),
                error: (error, stack) => _buildAnalyticsCard(
                  'Transactions',
                  'Error',
                  Icons.account_balance,
                  Colors.purple,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: lowStockAsync.when(
                data: (count) => _buildAnalyticsCard(
                  'Low Stock Items',
                  count.toString(),
                  Icons.warning,
                  Colors.red,
                ),
                loading: () => _buildAnalyticsCard(
                  'Low Stock Items',
                  '...',
                  Icons.warning,
                  Colors.red,
                ),
                error: (error, stack) => _buildAnalyticsCard(
                  'Low Stock Items',
                  'Error',
                  Icons.warning,
                  Colors.red,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: incomeAsync.when(
                data: (income) => expensesAsync.when(
                  data: (expenses) => _buildAnalyticsCard(
                    'Net Balance',
                    '\$${(income - expenses).toStringAsFixed(0)}',
                    (income - expenses) >= 0
                        ? Icons.trending_up
                        : Icons.trending_down,
                    (income - expenses) >= 0 ? Colors.green : Colors.red,
                  ),
                  loading: () => _buildAnalyticsCard(
                    'Net Balance',
                    '...',
                    Icons.trending_up,
                    Colors.green,
                  ),
                  error: (error, stack) => _buildAnalyticsCard(
                    'Net Balance',
                    'Error',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                loading: () => _buildAnalyticsCard(
                  'Net Balance',
                  '...',
                  Icons.trending_up,
                  Colors.green,
                ),
                error: (error, stack) => _buildAnalyticsCard(
                  'Net Balance',
                  'Error',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildFeatureCard(
          context,
          'Clients',
          Icons.people,
          Colors.blue,
          () => context.push('/clients'),
        ),
        _buildFeatureCard(
          context,
          'Inventory',
          Icons.inventory,
          Colors.green,
          () => context.push('/inventory'),
        ),
        _buildFeatureCard(
          context,
          'Invoicing',
          Icons.receipt,
          Colors.orange,
          () => context.push('/invoicing'),
        ),
        _buildFeatureCard(
          context,
          'Ledgers',
          Icons.account_balance,
          Colors.purple,
          () => context.push('/ledgers'),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.2),
              color.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

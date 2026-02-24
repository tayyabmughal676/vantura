import 'package:go_router/go_router.dart';
import '../../presentation/screens/chat_screen.dart';
import '../../presentation/screens/clients_screen.dart';
import '../../presentation/screens/dashboard_screen.dart';
import '../../presentation/screens/inventory_screen.dart';
import '../../presentation/screens/invoicing_screen.dart';
import '../../presentation/screens/ledgers_screen.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/client.dart';
import '../../domain/entities/inventory_item.dart';
import '../../presentation/screens/add_edit_client_screen.dart';
import '../../presentation/screens/add_edit_item_screen.dart';
import '../../presentation/screens/create_invoice_screen.dart';
import '../../presentation/screens/add_ledger_entry_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardScreen(),
      routes: [
        GoRoute(path: 'chat', builder: (context, state) => const ChatScreen()),
        GoRoute(
          path: 'clients',
          builder: (context, state) => const ClientsScreen(),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => const AddEditClientScreen(),
            ),
            GoRoute(
              path: 'edit',
              builder: (context, state) =>
                  AddEditClientScreen(client: state.extra as Client?),
            ),
          ],
        ),
        GoRoute(
          path: 'inventory',
          builder: (context, state) => const InventoryScreen(),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => const AddEditItemScreen(),
            ),
            GoRoute(
              path: 'edit',
              builder: (context, state) =>
                  AddEditItemScreen(item: state.extra as InventoryItem?),
            ),
          ],
        ),
        GoRoute(
          path: 'invoicing',
          builder: (context, state) => const InvoicingScreen(),
          routes: [
            GoRoute(
              path: 'create',
              builder: (context, state) {
                final typeStr = state.uri.queryParameters['type'] ?? 'invoice';
                final type = InvoiceType.values.firstWhere(
                  (e) => e.name == typeStr,
                  orElse: () => InvoiceType.invoice,
                );
                return CreateInvoiceScreen(type: type);
              },
            ),
          ],
        ),
        GoRoute(
          path: 'ledgers',
          builder: (context, state) => const LedgersScreen(),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) => const AddLedgerEntryScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

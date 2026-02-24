import 'package:vantura/core/index.dart';

/// Arguments for the NavigationTool.
class NavigationArgs {
  final String screen;
  final Map<String, dynamic>? params;

  NavigationArgs({required this.screen, this.params});

  factory NavigationArgs.fromJson(Map<String, dynamic> json) {
    return NavigationArgs(
      screen: json['screen'] as String,
      params: json['params'] as Map<String, dynamic>?,
    );
  }
}

/// A tool that allows the agent to navigate the user to different parts of the app.
/// Note: Since the agent runs in a service, this tool might need a way to
/// communicate with the UI. In this implementation, we will use a callback or
/// a stream that the UI listens to.
class NavigationTool extends VanturaTool<NavigationArgs> {
  final Function(String, Map<String, dynamic>?) onNavigate;

  NavigationTool({required this.onNavigate});

  @override
  String get name => 'navigate_to';

  @override
  String get description =>
      'Navigates the user to a specific screen in the app';

  @override
  Map<String, dynamic> get parameters => SchemaHelper.generateSchema(
    {
      'screen': SchemaHelper.stringProperty(
        description:
            'The target screen name. Map to internal routes: "dashboard" (/), "clients" (/clients), "clients/add" (/clients/add), "inventory" (/inventory), "inventory/add" (/inventory/add), "invoicing" (/invoicing), "invoicing/create" (/invoicing/create), "ledgers" (/ledgers), "ledgers/add" (/ledgers/add), "chat" (/chat).',
        enumValues: [
          'dashboard',
          'clients',
          'clients/add',
          'inventory',
          'inventory/add',
          'invoicing',
          'invoicing/create',
          'ledgers',
          'ledgers/add',
          'chat',
        ],
      ),
      'params': {
        'type': 'object',
        'description': 'Optional parameters for the screen',
      },
    },
    required: ['screen'],
  );

  @override
  NavigationArgs parseArgs(Map<String, dynamic> json) =>
      NavigationArgs.fromJson(json);

  @override
  Future<String> execute(NavigationArgs args) async {
    try {
      onNavigate(args.screen, args.params);
      return 'Successfully navigation request to ${args.screen} initiated.';
    } catch (e) {
      return 'Error navigating: $e';
    }
  }
}

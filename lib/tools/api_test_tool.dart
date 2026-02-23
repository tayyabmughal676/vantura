import 'package:http/http.dart' as http;
import '../core/index.dart';

/// Arguments for the ApiTestTool.
class ApiTestArgs {
  final String url;
  final String? method;

  ApiTestArgs({required this.url, this.method});

  /// Creates ApiTestArgs from a JSON map.
  factory ApiTestArgs.fromJson(Map<String, dynamic> json) {
    return ApiTestArgs(
      url: json['url'] as String,
      method: json['method'] as String?,
    );
  }
}

class ApiTestTool extends VanturaTool<ApiTestArgs> {
  /// Blacklist of sensitive hostnames to prevent SSRF.
  final List<String> hostnameBlacklist;

  ApiTestTool({
    this.hostnameBlacklist = const [
      'localhost',
      '127.0.0.1',
      '0.0.0.0',
      '169.254.169.254', // Metadata service
      'metadata.google.internal',
    ],
  });

  @override
  String get name => 'api_test';

  @override
  String get description => 'Tests an API endpoint by sending a request';

  @override
  Map<String, dynamic> get parameters => SchemaHelper.generateSchema(
    {
      'url': SchemaHelper.stringProperty(
        description: 'The URL of the API endpoint to test',
      ),
      'method': SchemaHelper.stringProperty(
        description: 'HTTP method to use (default: GET)',
        enumValues: ['GET', 'POST', 'PUT', 'DELETE'],
      ),
    },
    required: ['url'],
  );

  @override
  ApiTestArgs parseArgs(Map<String, dynamic> json) =>
      ApiTestArgs.fromJson(json);

  @override
  Future<String> execute(ApiTestArgs args) async {
    try {
      final uri = Uri.parse(args.url);

      // Basic SSRF protection
      if (hostnameBlacklist.any(
        (h) => uri.host.toLowerCase() == h.toLowerCase(),
      )) {
        return 'Error: Access to blocked hostname "${uri.host}" is restricted.';
      }

      final method = args.method ?? 'GET';

      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri);
          break;
        case 'POST':
          response = await http.post(uri);
          break;
        case 'PUT':
          response = await http.put(uri);
          break;
        case 'DELETE':
          response = await http.delete(uri);
          break;
        default:
          return 'Unsupported HTTP method: $method';
      }

      // Very strict snippet to prevent leaking large tokens or PII in the prompt history
      final bodySnippet = response.body.length > 100
          ? '${response.body.substring(0, 100)}... [TRUNCATED]'
          : response.body;

      return 'Status: ${response.statusCode}, Length: ${response.body.length}, Body Snippet: $bodySnippet';
    } catch (e) {
      return 'Error testing API: $e';
    }
  }
}

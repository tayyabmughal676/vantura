import 'package:http/http.dart' as http;
import '../core/index.dart';

/// Arguments for the ApiTestTool.
class ApiTestArgs {
  final String url;
  final String? method;

  ApiTestArgs({
    required this.url,
    this.method,
  });

  /// Creates ApiTestArgs from a JSON map.
  factory ApiTestArgs.fromJson(Map<String, dynamic> json) {
    return ApiTestArgs(
      url: json['url'] as String,
      method: json['method'] as String?,
    );
  }
}

class ApiTestTool extends VanturaTool<ApiTestArgs> {
  @override
  String get name => 'api_test';

  @override
  String get description => 'Tests an API endpoint by sending a request';

  @override
  Map<String, dynamic> get parameters => SchemaHelper.generateSchema({
    'url': SchemaHelper.stringProperty(
      description: 'The URL of the API endpoint to test',
    ),
    'method': SchemaHelper.stringProperty(
      description: 'HTTP method to use (default: GET)',
      enumValues: ['GET', 'POST', 'PUT', 'DELETE'],
    ),
  }, required: ['url']);

  @override
  ApiTestArgs parseArgs(Map<String, dynamic> json) => ApiTestArgs.fromJson(json);

  @override
  Future<String> execute(ApiTestArgs args) async {
    try {
      final url = args.url;
      final method = args.method ?? 'GET';

      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(Uri.parse(url));
          break;
        case 'POST':
          response = await http.post(Uri.parse(url));
          break;
        case 'PUT':
          response = await http.put(Uri.parse(url));
          break;
        case 'DELETE':
          response = await http.delete(Uri.parse(url));
          break;
        default:
          return 'Unsupported HTTP method: $method';
      }

      final bodySnippet = response.body.length > 200
          ? '${response.body.substring(0, 200)}...'
          : response.body;
      return 'Status: ${response.statusCode}, Body: $bodySnippet';
    } catch (e) {
      return 'Error testing API: $e';
    }
  }
}

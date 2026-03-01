import 'package:flutter_test/flutter_test.dart';
import 'package:vantura/tools/api_test_tool.dart';

void main() {
  group('ApiTestArgs', () {
    test('fromJson parses standard values', () {
      final json = {'url': 'https://example.com', 'method': 'GET'};
      final args = ApiTestArgs.fromJson(json);
      expect(args.url, 'https://example.com');
      expect(args.method, 'GET');
    });

    test('fromJson defaults optional parameters to null', () {
      final json = {'url': 'https://example.com'};
      final args = ApiTestArgs.fromJson(json);
      expect(args.url, 'https://example.com');
      expect(args.method, isNull);
    });
  });

  group('ApiTestTool', () {
    late ApiTestTool tool;

    setUp(() {
      tool = ApiTestTool();
    });

    test('metadata is correct', () {
      expect(tool.name, 'api_test');
      expect(tool.description, 'Tests an API endpoint by sending a request');
      expect(tool.parameters['required'], contains('url'));
    });

    test('parseArgs delegates to ApiTestArgs', () {
      final args = tool.parseArgs({
        'url': 'https://test.com',
        'method': 'POST',
      });
      expect(args.url, 'https://test.com');
      expect(args.method, 'POST');
    });

    group('SSRF protection', () {
      test('blocks localhost access', () async {
        final result = await tool.execute(
          ApiTestArgs(url: 'http://localhost/admin'),
        );
        expect(
          result,
          contains(
            'Error: Access to blocked hostname "localhost" is restricted.',
          ),
        );
      });

      test('blocks 127.0.0.1 access', () async {
        final result = await tool.execute(
          ApiTestArgs(url: 'http://127.0.0.1:8080'),
        );
        expect(
          result,
          contains(
            'Error: Access to blocked hostname "127.0.0.1" is restricted.',
          ),
        );
      });

      test('blocks 0.0.0.0 access', () async {
        final result = await tool.execute(ApiTestArgs(url: 'http://0.0.0.0'));
        expect(
          result,
          contains(
            'Error: Access to blocked hostname "0.0.0.0" is restricted.',
          ),
        );
      });

      test('blocks metadata API', () async {
        final result = await tool.execute(
          ApiTestArgs(url: 'http://metadata.google.internal'),
        );
        expect(
          result,
          contains(
            'Error: Access to blocked hostname "metadata.google.internal" is restricted.',
          ),
        );
      });

      test('case insensitive blocking check', () async {
        final result = await tool.execute(ApiTestArgs(url: 'http://LocalHost'));
        expect(
          result,
          contains(
            'Error: Access to blocked hostname "localhost" is restricted.',
          ),
        );
      });
    });

    group('Execution Error Handling', () {
      test('rejects totally invalid schemes smoothly', () async {
        final result = await tool.execute(ApiTestArgs(url: 'not-a-url'));
        expect(result, contains('Error test'));
      });

      test('unsupported method throws error', () async {
        final result = await tool.execute(
          ApiTestArgs(url: 'http://example.com', method: 'PATCH'),
        );
        expect(result, 'Unsupported HTTP method: PATCH');
      });
    });
  });
}

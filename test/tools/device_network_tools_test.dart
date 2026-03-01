import 'package:flutter_test/flutter_test.dart';
import 'package:vantura/tools/device_info_tool.dart';
import 'package:vantura/tools/network_connectivity_tool.dart';

void main() {
  group('DeviceInfoArgs', () {
    test('fromJson creates instance', () {
      final json = <String, dynamic>{};
      final args = DeviceInfoArgs.fromJson(json);
      expect(args, isA<DeviceInfoArgs>());
    });
  });

  group('DeviceInfoTool', () {
    late DeviceInfoTool tool;

    setUp(() {
      tool = DeviceInfoTool();
    });

    test('metadata is correct', () {
      expect(tool.name, 'device_info');
      expect(tool.description, 'Retrieves basic device information');
      expect(tool.parameters, isEmpty);
    });

    test('parseArgs returns correct type', () {
      final args = tool.parseArgs({});
      expect(args, isA<DeviceInfoArgs>());
    });

    test('execute throws error when no plugin registered (in testing)', () async {
      final result = await tool.execute(DeviceInfoArgs());
      // Since `flutter_test` doesn't provide MethodChannels for device_info by default,
      // it should return the caught platform exception or error string gracefully.
      expect(result, contains('Error retrieving device info'));
    });
  });

  group('NetworkConnectivityArgs', () {
    test('fromJson creates instance', () {
      final json = <String, dynamic>{};
      final args = NetworkConnectivityArgs.fromJson(json);
      expect(args, isA<NetworkConnectivityArgs>());
    });
  });

  group('NetworkConnectivityTool', () {
    late NetworkConnectivityTool tool;

    setUp(() {
      tool = NetworkConnectivityTool();
    });

    test('metadata is correct', () {
      expect(tool.name, 'network_connectivity');
      expect(
        tool.description,
        'Checks the current network connectivity status',
      );
      expect(tool.parameters, isEmpty);
    });

    test('parseArgs returns correct type', () {
      final args = tool.parseArgs({});
      expect(args, isA<NetworkConnectivityArgs>());
    });

    test('execute throws error when no plugin registered (in testing)', () async {
      final result = await tool.execute(NetworkConnectivityArgs());
      // Same as above, without MethodChannel mocks, it catches the error and returns a string
      expect(result, contains('Error checking connectivity'));
    });
  });
}

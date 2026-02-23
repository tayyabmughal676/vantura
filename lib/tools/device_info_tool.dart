import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../core/index.dart';

/// Arguments for the DeviceInfoTool.
class DeviceInfoArgs {
  DeviceInfoArgs();

  /// Creates DeviceInfoArgs from a JSON map.
  factory DeviceInfoArgs.fromJson(Map<String, dynamic> json) => DeviceInfoArgs();
}

class DeviceInfoTool extends VanturaTool<DeviceInfoArgs> {
  @override
  String get name => 'device_info';

  @override
  String get description => 'Retrieves basic device information';

  @override
  Map<String, dynamic> get parameters => {};

  @override
  DeviceInfoArgs parseArgs(Map<String, dynamic> json) => DeviceInfoArgs.fromJson(json);

  @override
  Future<String> execute(DeviceInfoArgs args) async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await deviceInfoPlugin.androidInfo;
        return 'Platform: Android, Model: ${info.model}, Version: ${info.version.release}';
      } else if (Platform.isIOS) {
        final info = await deviceInfoPlugin.iosInfo;
        return 'Platform: iOS, Model: ${info.model}, Version: ${info.systemVersion}';
      } else if (Platform.isWindows) {
        final info = await deviceInfoPlugin.windowsInfo;
        return 'Platform: Windows, Computer name: ${info.computerName}';
      } else if (Platform.isMacOS) {
        final info = await deviceInfoPlugin.macOsInfo;
        return 'Platform: macOS, Model: ${info.model}';
      } else if (Platform.isLinux) {
        final info = await deviceInfoPlugin.linuxInfo;
        return 'Platform: Linux, Name: ${info.name}';
      } else {
        return 'Platform: Unknown';
      }
    } catch (e) {
      return 'Error retrieving device info: $e';
    }
  }
}

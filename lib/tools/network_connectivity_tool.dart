import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/index.dart';

/// Arguments for the NetworkConnectivityTool.
class NetworkConnectivityArgs {
  NetworkConnectivityArgs();

  /// Creates NetworkConnectivityArgs from a JSON map.
  factory NetworkConnectivityArgs.fromJson(Map<String, dynamic> json) =>
      NetworkConnectivityArgs();
}

/// A tool for checking the device's current network connectivity status.
///
/// Uses the `connectivity_plus` package to detect WiFi, Mobile, or no connection.
class NetworkConnectivityTool extends VanturaTool<NetworkConnectivityArgs> {
  @override
  String get name => 'network_connectivity';

  @override
  String get description => 'Checks the current network connectivity status';

  @override
  Map<String, dynamic> get parameters => {};

  @override
  NetworkConnectivityArgs parseArgs(Map<String, dynamic> json) =>
      NetworkConnectivityArgs.fromJson(json);

  @override
  Future<String> execute(NetworkConnectivityArgs args) async {
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      final hasInternet = !connectivityResults.contains(
        ConnectivityResult.none,
      );
      return 'Connectivity status: $connectivityResults. Internet available: $hasInternet';
    } catch (e) {
      return 'Error checking connectivity: $e';
    }
  }
}

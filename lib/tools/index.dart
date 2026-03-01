import '../core/index.dart';
import 'calculator_tool.dart';
import 'network_connectivity_tool.dart';
import 'device_info_tool.dart';
import 'api_test_tool.dart';

export 'calculator_tool.dart';
export 'network_connectivity_tool.dart';
export 'device_info_tool.dart';
export 'api_test_tool.dart';

/// Returns a list of all standard tools available in the SDK.
///
/// Includes [CalculatorTool], [NetworkConnectivityTool], [DeviceInfoTool], and [ApiTestTool].
List<VanturaTool> getStandardTools() {
  return [
    CalculatorTool(),
    NetworkConnectivityTool(),
    DeviceInfoTool(),
    ApiTestTool(),
  ];
}

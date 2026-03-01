import 'package:http/http.dart' as http;
import 'package:vantura/core/index.dart';
import 'package:mockito/annotations.dart';

// This will generate a mocks.mocks.dart file with all our mock classes
@GenerateMocks([
  http.Client,
  VanturaMemory,
  VanturaState,
  VanturaLogger,
  VanturaPersistence,
  VanturaClient,
])
void main() {}

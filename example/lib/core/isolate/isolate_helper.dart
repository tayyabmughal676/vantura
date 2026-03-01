import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import '../utils/logger.dart';

/// Demonstrates running heavy JSON parsing operations in a Dart [Isolate]
/// to guarantee zero dropped frames on the main UI thread.
///
/// ## Why This Matters
/// In production Vantura apps, the agent may invoke tools that return
/// large JSON payloads (e.g., listing hundreds of inventory items or
/// generating complex analytics). Parsing these on the main UI isolate
/// can cause frame drops and janky scrolling.
///
/// ## Usage
/// ```dart
/// // Instead of parsing on the main thread:
/// final data = jsonDecode(largeJsonString); // ❌ Blocks UI
///
/// // Use IsolateHelper for heavy payloads:
/// final data = await IsolateHelper.parseJson(largeJsonString); // ✅ UI-safe
/// ```
///
/// ## Integration with Vantura Tools
/// Override a tool's `execute()` method to offload heavy serialization:
/// ```dart
/// class HeavyListTool extends VanturaTool<ListArgs> {
///   @override
///   Future<String> execute(ListArgs args) async {
///     final rawData = await database.queryAll();
///     // Offload the JSON encoding to an isolate
///     final jsonResult = await IsolateHelper.encodeJson(rawData);
///     return jsonResult;
///   }
/// }
/// ```
class IsolateHelper {
  /// Parses a JSON string in a background isolate.
  /// Returns the decoded object (Map, List, etc.).
  ///
  /// Only use this for payloads > ~50KB. For small payloads,
  /// the isolate spawn overhead outweighs the benefit.
  static Future<dynamic> parseJson(String jsonString) async {
    final stopwatch = Stopwatch()..start();

    appLogger.info(
      'Offloading JSON parsing to isolate (${jsonString.length} chars)',
      tag: 'ISOLATE',
      extra: {'payload_size': jsonString.length},
    );

    try {
      final result = await Isolate.run(() => jsonDecode(jsonString));

      stopwatch.stop();
      appLogger.info(
        'Isolate JSON parsing completed in ${stopwatch.elapsedMilliseconds}ms',
        tag: 'ISOLATE',
        extra: {
          'duration_ms': stopwatch.elapsedMilliseconds,
          'payload_size': jsonString.length,
        },
      );

      return result;
    } catch (e, stackTrace) {
      stopwatch.stop();
      appLogger.error(
        'Isolate JSON parsing failed',
        tag: 'ISOLATE',
        error: e,
        stackTrace: stackTrace,
      );
      // Fallback: parse on main thread
      return jsonDecode(jsonString);
    }
  }

  /// Encodes a Dart object to JSON string in a background isolate.
  /// Useful when encoding large tool results before returning to the agent.
  static Future<String> encodeJson(dynamic data) async {
    final stopwatch = Stopwatch()..start();

    appLogger.info('Offloading JSON encoding to isolate', tag: 'ISOLATE');

    try {
      final result = await Isolate.run(() => jsonEncode(data));

      stopwatch.stop();
      appLogger.info(
        'Isolate JSON encoding completed in ${stopwatch.elapsedMilliseconds}ms',
        tag: 'ISOLATE',
        extra: {
          'duration_ms': stopwatch.elapsedMilliseconds,
          'result_size': result.length,
        },
      );

      return result;
    } catch (e, stackTrace) {
      stopwatch.stop();
      appLogger.error(
        'Isolate JSON encoding failed',
        tag: 'ISOLATE',
        error: e,
        stackTrace: stackTrace,
      );
      // Fallback: encode on main thread
      return jsonEncode(data);
    }
  }

  /// Performs a batch operation on a list of items in a background isolate.
  /// Useful for transforming large data sets (e.g., tool results)
  /// without blocking the UI.
  ///
  /// Example:
  /// ```dart
  /// final formatted = await IsolateHelper.batchProcess<Map, String>(
  ///   rawItems,
  ///   (item) => '${item["name"]}: \$${item["price"]}',
  /// );
  /// ```
  static Future<List<R>> batchProcess<T, R>(
    List<T> items,
    R Function(T item) processor,
  ) async {
    if (items.length < 100) {
      // For small lists, no benefit from isolate overhead
      return items.map(processor).toList();
    }

    final stopwatch = Stopwatch()..start();

    appLogger.info(
      'Offloading batch processing to isolate (${items.length} items)',
      tag: 'ISOLATE',
      extra: {'item_count': items.length},
    );

    try {
      final result = await Isolate.run(() => items.map(processor).toList());

      stopwatch.stop();
      appLogger.info(
        'Isolate batch processing completed in ${stopwatch.elapsedMilliseconds}ms',
        tag: 'ISOLATE',
        extra: {
          'duration_ms': stopwatch.elapsedMilliseconds,
          'item_count': items.length,
        },
      );

      return result;
    } catch (e) {
      // Fallback: process on main thread
      return items.map(processor).toList();
    }
  }
}

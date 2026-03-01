import 'dart:convert';

/// Represents a serialized snapshot of an agent's execution state.
/// This allows resuming interrupted sessions if the app is closed
/// during a tool execution or long generation.
class AgentStateCheckpoint {
  /// Whether the agent was running when the checkpoint was saved.
  final bool isRunning;

  /// The description of the current step.
  final String currentStep;

  /// The current iteration count in the ReAct loop.
  final int iterationCount;

  /// Any error message present at the time of the checkpoint.
  final String? errorMessage;

  /// The timestamp of the checkpoint.
  final DateTime timestamp;

  /// Creates a new [AgentStateCheckpoint].
  const AgentStateCheckpoint({
    required this.isRunning,
    required this.currentStep,
    required this.iterationCount,
    this.errorMessage,
    required this.timestamp,
  });

  /// Creates a checkpoint from a JSON map.
  factory AgentStateCheckpoint.fromJson(Map<String, dynamic> json) {
    return AgentStateCheckpoint(
      isRunning: json['isRunning'] as bool? ?? false,
      currentStep: json['currentStep'] as String? ?? '',
      iterationCount: json['iterationCount'] as int? ?? 0,
      errorMessage: json['errorMessage'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  /// Converts this checkpoint to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'isRunning': isRunning,
      'currentStep': currentStep,
      'iterationCount': iterationCount,
      'errorMessage': errorMessage,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Returns the checkpoint as a JSON string.
  String toJsonString() => jsonEncode(toJson());

  /// Creates a checkpoint from a JSON string.
  factory AgentStateCheckpoint.fromJsonString(String source) =>
      AgentStateCheckpoint.fromJson(jsonDecode(source) as Map<String, dynamic>);
}

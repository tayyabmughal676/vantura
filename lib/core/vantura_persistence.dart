import 'agent_state_checkpoint.dart';

/// Interface for persistent storage of agent memory.
///
/// This allows the SDK to remain decoupled from any specific database implementation.
abstract class VanturaPersistence {
  /// Saves a message to the persistent store.
  Future<void> saveMessage(
    String role,
    String content, {
    bool isSummary = false,
    List<Map<String, dynamic>>? toolCalls,
    String? toolCallId,
  });

  /// Retrieves all saved messages from the persistent store.
  Future<List<Map<String, dynamic>>> loadMessages();

  /// Clears all saved messages from the persistent store.
  Future<void> clearMessages();

  /// Deletes older messages to maintain a specific limit.
  Future<void> deleteOldMessages(int limit);

  /// Saves the agent's execution checkpoint to persistent storage.
  /// This allows resuming exactly where the agent left off if interrupted.
  Future<void> saveCheckpoint(AgentStateCheckpoint checkpoint) async {}

  /// Loads the most recent execution checkpoint.
  /// Returns null if no checkpoint exists.
  Future<AgentStateCheckpoint?> loadCheckpoint() async => null;

  /// Clears the saved checkpoint (e.g., after successful completion).
  Future<void> clearCheckpoint() async {}
}

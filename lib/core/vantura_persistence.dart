/// Interface for persistent storage of agent memory.
///
/// This allows the SDK to remain decoupled from any specific database implementation.
abstract class VanturaPersistence {
  /// Saves a message to the persistent store.
  Future<void> saveMessage(
    String role,
    String content, {
    bool isSummary = false,
  });

  /// Retrieves all saved messages from the persistent store.
  Future<List<Map<String, dynamic>>> loadMessages();

  /// Clears all saved messages from the persistent store.
  Future<void> clearMessages();

  /// Deletes older messages to maintain a specific limit.
  Future<void> deleteOldMessages(int limit);
}

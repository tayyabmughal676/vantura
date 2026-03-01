import 'package:vantura/core/index.dart';

import 'database_helper.dart';

/// App-side implementation of [VanturaPersistence] using [DatabaseHelper].
class PersistentMemoryImpl implements VanturaPersistence {
  final DatabaseHelper _db;

  PersistentMemoryImpl(this._db);

  @override
  Future<void> saveMessage(
    String role,
    String content, {
    bool isSummary = false,
    String? toolCallId,
    List<Map<String, dynamic>>? toolCalls,
  }) async {
    await _db.insertChatMessage(
      role,
      content,
      isSummary: isSummary,
      toolCallId: toolCallId,
      toolCalls: toolCalls,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> loadMessages() async {
    return await _db.getChatMessages();
  }

  @override
  Future<void> clearMessages() async {
    await _db.clearChatHistory();
  }

  @override
  Future<void> deleteOldMessages(int limit) async {
    await _db.deleteOldMessages(limit);
  }

  @override
  Future<void> saveCheckpoint(AgentStateCheckpoint checkpoint) async {
    await _db.saveCheckpoint(checkpoint.toJson());
  }

  @override
  Future<AgentStateCheckpoint?> loadCheckpoint() async {
    final json = await _db.loadCheckpoint();
    if (json != null) {
      return AgentStateCheckpoint.fromJson(json);
    }
    return null;
  }

  @override
  Future<void> clearCheckpoint() async {
    await _db.clearCheckpoint();
  }
}

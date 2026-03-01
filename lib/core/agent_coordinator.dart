/// Core coordination logic for managing multiple Vantura agents.
library agent_coordinator;

import 'dart:async';
import 'index.dart';

/// Coordinates multiple [VanturaAgent]s, allowing them to hand off the conversation
/// to each other based on user needs.
///
/// The [AgentCoordinator] acts as a router, managing which agent is currently
/// handling the interaction and facilitating transfers between agents via
/// a built-in transfer tool.
class AgentCoordinator {
  /// Map of all available agents, indexed by their [VanturaAgent.name].
  final Map<String, VanturaAgent> agents = {};

  /// The agent currently responsible for processing user requests.
  late VanturaAgent activeAgent;
  String? _pendingTransfer;

  /// Creates a coordinator with a list of agents. The first agent in the list
  /// is set as the initial default/active agent.
  AgentCoordinator(List<VanturaAgent> agentList) {
    if (agentList.isEmpty) {
      throw ArgumentError('AgentCoordinator requires at least one agent.');
    }

    for (var agent in agentList) {
      agents[agent.name] = agent;
    }

    activeAgent = agentList.first;

    // Inject the handoff tool into all agents
    final handoffTool = _AgentTransferTool(this);
    for (var agent in agentList) {
      agent.addTool(handoffTool);
    }
  }

  /// Triggers a handoff to the [targetAgentName].
  ///
  /// The transfer will take effect on the NEXT run or iteration.
  void triggerHandoff(String targetAgentName) {
    if (agents.containsKey(targetAgentName)) {
      _pendingTransfer = targetAgentName;
    }
  }

  /// Runs the current active agent. Hand-off checks are performed after completion.
  Future<VanturaResponse> run(
    String prompt, {
    CancellationToken? cancellationToken,
  }) async {
    // Standard run using active agent
    final response = await activeAgent.run(
      prompt,
      cancellationToken: cancellationToken,
    );

    // If a transfer was requested during execution
    if (_pendingTransfer != null) {
      activeAgent = agents[_pendingTransfer]!;
      _pendingTransfer = null;

      // Optionally, we could immediately trigger the new agent to respond back
      // Since memory is shared, the new agent will see the history
      // We'll leave it simple for now: the NEXT user query goes to the new agent.
      // E.g., The original agent: "I am transferring you to X." (Tool called).
    }

    return response;
  }

  /// Streams the current active agent. Hand-off checks are performed after completion.
  Stream<VanturaResponse> runStreaming(
    String prompt, {
    CancellationToken? cancellationToken,
  }) async* {
    final stream = activeAgent.runStreaming(
      prompt,
      cancellationToken: cancellationToken,
    );

    await for (final response in stream) {
      yield response;
    }

    // Process any transfer requested during streaming
    if (_pendingTransfer != null) {
      activeAgent = agents[_pendingTransfer]!;
      _pendingTransfer = null;
    }
  }
}

/// Dynamic tool injected into agents to allow them to transfer control to others
class _AgentTransferTool extends VanturaTool<Map<String, dynamic>> {
  final AgentCoordinator _coordinator;

  _AgentTransferTool(this._coordinator);

  @override
  String get name => 'transfer_to_agent';

  @override
  String get description =>
      'Transfer the conversation to another specialized agent. Only do this if the user request requires the specific expertise of the other agent.';

  @override
  Map<String, dynamic> get parameters => {
    'type': 'object',
    'properties': {
      'target_agent': {
        'type': 'string',
        'description': 'The exact name of the agent to transfer to.',
        'enum': _coordinator.agents.keys.toList(),
      },
      'reason': {
        'type': 'string',
        'description':
            'Reason for transfer so the next agent understands context.',
      },
    },
    'required': ['target_agent', 'reason'],
  };

  @override
  Map<String, dynamic> parseArgs(Map<String, dynamic> json) => json;

  @override
  Future<String> execute(Map<String, dynamic> args) async {
    final target = args['target_agent'] as String;
    final reason = args['reason'] as String;

    if (!_coordinator.agents.containsKey(target)) {
      return 'Error: Agent "$target" not found. Available agents: ${_coordinator.agents.keys.join(', ')}';
    }

    _coordinator.triggerHandoff(target);
    return 'SUCCESS. You have transferred control to $target. Stop responding and let the new agent take over for the next request. Reason provided: $reason';
  }
}

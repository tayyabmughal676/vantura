import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:vantura/core/index.dart';

import '../mocks/mocks.mocks.dart';

void main() {
  group('AgentCoordinator', () {
    late MockVanturaClient mockClient;
    late MockVanturaMemory mockMemory;
    late VanturaState state1;
    late VanturaState state2;

    Map<String, dynamic> _textResponse(String text) {
      return {
        'choices': [
          {
            'message': {'role': 'assistant', 'content': text},
            'finish_reason': 'stop',
          },
        ],
        'usage': {
          'prompt_tokens': 10,
          'completion_tokens': 5,
          'total_tokens': 15,
        },
      };
    }

    setUp(() {
      mockClient = MockVanturaClient();
      mockMemory = MockVanturaMemory();
      when(mockMemory.persistence).thenReturn(null);
      state1 = VanturaState();
      state2 = VanturaState();

      when(mockMemory.getMessages()).thenReturn([]);
      when(
        mockMemory.addMessage(
          any,
          any,
          toolCalls: anyNamed('toolCalls'),
          toolCallId: anyNamed('toolCallId'),
        ),
      ).thenAnswer((_) async {});
    });

    VanturaAgent _createAgent({
      required String name,
      required String description,
      required VanturaState state,
      List<VanturaTool>? tools,
    }) {
      return VanturaAgent(
        instructions: 'You are $name.',
        memory: mockMemory,
        tools: tools ?? [],
        client: mockClient,
        state: state,
        name: name,
        description: description,
      );
    }

    test('throws when created with empty agent list', () {
      expect(() => AgentCoordinator([]), throwsA(isA<ArgumentError>()));
    });

    test('first agent is set as the active agent', () {
      final agent1 = _createAgent(
        name: 'agent_a',
        description: 'Agent A',
        state: state1,
      );
      final agent2 = _createAgent(
        name: 'agent_b',
        description: 'Agent B',
        state: state2,
      );

      final coordinator = AgentCoordinator([agent1, agent2]);
      expect(coordinator.activeAgent.name, 'agent_a');
    });

    test('injects transfer_to_agent tool into all agents', () {
      final agent1 = _createAgent(
        name: 'agent_a',
        description: 'Agent A',
        state: state1,
      );
      final agent2 = _createAgent(
        name: 'agent_b',
        description: 'Agent B',
        state: state2,
      );

      AgentCoordinator([agent1, agent2]);

      expect(agent1.tools.any((t) => t.name == 'transfer_to_agent'), isTrue);
      expect(agent2.tools.any((t) => t.name == 'transfer_to_agent'), isTrue);
    });

    test('run delegates to the active agent', () async {
      when(
        mockClient.sendChatRequest(
          any,
          any,
          cancellationToken: anyNamed('cancellationToken'),
        ),
      ).thenAnswer((_) async => _textResponse('Hello from A'));

      final agent1 = _createAgent(
        name: 'agent_a',
        description: 'Agent A',
        state: state1,
      );
      final agent2 = _createAgent(
        name: 'agent_b',
        description: 'Agent B',
        state: state2,
      );

      final coordinator = AgentCoordinator([agent1, agent2]);
      final response = await coordinator.run('hello');

      expect(response.text, 'Hello from A');
    });

    test('triggerHandoff changes active agent on next run', () async {
      when(
        mockClient.sendChatRequest(
          any,
          any,
          cancellationToken: anyNamed('cancellationToken'),
        ),
      ).thenAnswer((_) async => _textResponse('response'));

      final agent1 = _createAgent(
        name: 'agent_a',
        description: 'Agent A',
        state: state1,
      );
      final agent2 = _createAgent(
        name: 'agent_b',
        description: 'Agent B',
        state: state2,
      );

      final coordinator = AgentCoordinator([agent1, agent2]);

      // Trigger a handoff
      coordinator.triggerHandoff('agent_b');

      // Run to process it
      await coordinator.run('test');

      // Active agent should now be agent_b
      expect(coordinator.activeAgent.name, 'agent_b');
    });

    test('triggerHandoff to unknown agent is ignored', () async {
      when(
        mockClient.sendChatRequest(
          any,
          any,
          cancellationToken: anyNamed('cancellationToken'),
        ),
      ).thenAnswer((_) async => _textResponse('response'));

      final agent1 = _createAgent(
        name: 'agent_a',
        description: 'Agent A',
        state: state1,
      );

      final coordinator = AgentCoordinator([agent1]);
      coordinator.triggerHandoff('nonexistent');

      await coordinator.run('test');

      // Should remain agent_a
      expect(coordinator.activeAgent.name, 'agent_a');
    });

    test('works with a single agent', () async {
      when(
        mockClient.sendChatRequest(
          any,
          any,
          cancellationToken: anyNamed('cancellationToken'),
        ),
      ).thenAnswer((_) async => _textResponse('Only agent'));

      final agent = _createAgent(
        name: 'solo',
        description: 'Solo agent',
        state: state1,
      );

      final coordinator = AgentCoordinator([agent]);
      final response = await coordinator.run('hi');

      expect(response.text, 'Only agent');
      expect(coordinator.activeAgent.name, 'solo');
    });
  });
}

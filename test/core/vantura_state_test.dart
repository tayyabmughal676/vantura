import 'package:flutter_test/flutter_test.dart';
import 'package:vantura/core/vantura_state.dart';

void main() {
  group('VanturaState', () {
    late VanturaState state;
    late List<String> notifyLog;

    setUp(() {
      state = VanturaState();
      notifyLog = [];
      state.addListener(() => notifyLog.add('notified'));
    });

    tearDown(() {
      state.dispose();
    });

    test('initial state is idle', () {
      expect(state.isRunning, isFalse);
      expect(state.currentStep, '');
      expect(state.errorMessage, isNull);
    });

    group('startRun', () {
      test('sets isRunning to true', () {
        state.startRun();
        expect(state.isRunning, isTrue);
      });

      test('sets currentStep to initializing message', () {
        state.startRun();
        expect(state.currentStep, 'Initializing agent run...');
      });

      test('clears any previous errorMessage', () {
        state.failRun('previous error');
        notifyLog.clear();
        state.startRun();
        expect(state.errorMessage, isNull);
      });

      test('notifies listeners', () {
        state.startRun();
        expect(notifyLog, isNotEmpty);
      });
    });

    group('updateStep', () {
      test('updates currentStep', () {
        state.updateStep('Processing...');
        expect(state.currentStep, 'Processing...');
      });

      test('notifies listeners', () {
        state.updateStep('step');
        expect(notifyLog, isNotEmpty);
      });
    });

    group('completeRun', () {
      test('sets isRunning to false', () {
        state.startRun();
        state.completeRun();
        expect(state.isRunning, isFalse);
      });

      test('sets currentStep to completed message', () {
        state.startRun();
        state.completeRun();
        expect(state.currentStep, 'Run completed');
      });

      test('notifies listeners', () {
        notifyLog.clear();
        state.completeRun();
        expect(notifyLog, isNotEmpty);
      });
    });

    group('failRun', () {
      test('sets isRunning to false', () {
        state.startRun();
        state.failRun('oops');
        expect(state.isRunning, isFalse);
      });

      test('sets errorMessage', () {
        state.failRun('something went wrong');
        expect(state.errorMessage, 'something went wrong');
      });

      test('sets currentStep to failed message', () {
        state.failRun('err');
        expect(state.currentStep, 'Run failed');
      });

      test('notifies listeners', () {
        notifyLog.clear();
        state.failRun('err');
        expect(notifyLog, isNotEmpty);
      });
    });

    group('reset', () {
      test('resets all state to idle', () {
        state.startRun();
        state.updateStep('doing stuff');
        state.failRun('failed');
        state.reset();

        expect(state.isRunning, isFalse);
        expect(state.currentStep, '');
        expect(state.errorMessage, isNull);
      });

      test('notifies listeners', () {
        notifyLog.clear();
        state.reset();
        expect(notifyLog, isNotEmpty);
      });
    });

    test('full lifecycle: start → update → complete', () {
      state.startRun();
      expect(state.isRunning, isTrue);

      state.updateStep('Thinking...');
      expect(state.currentStep, 'Thinking...');

      state.completeRun();
      expect(state.isRunning, isFalse);
      expect(state.currentStep, 'Run completed');
      expect(state.errorMessage, isNull);
    });

    test('full lifecycle: start → update → fail', () {
      state.startRun();
      state.updateStep('Working...');
      state.failRun('timeout');

      expect(state.isRunning, isFalse);
      expect(state.currentStep, 'Run failed');
      expect(state.errorMessage, 'timeout');
    });
  });
}

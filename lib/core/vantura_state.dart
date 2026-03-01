import 'package:flutter/foundation.dart';
import 'logger.dart';

/// Manages the state of an VanturaAgent run for UI synchronization.
///
/// Uses ChangeNotifier to notify listeners of state changes during
/// the agent's reasoning loop, enabling real-time UI updates.
class VanturaState extends ChangeNotifier {
  /// Whether the agent is currently running.
  bool isRunning = false;

  /// Current step in the agent's reasoning loop.
  String currentStep = '';

  /// Any error message, if the run failed.
  String? errorMessage;

  /// Start a new agent run.
  /// Initializes the state for a new agent interaction.
  void startRun() {
    isRunning = true;
    currentStep = 'Initializing agent run...';
    errorMessage = null;
    sdkLogger.info('Agent run started', tag: 'STATE');
    notifyListeners();
  }

  /// Update the current step.
  /// Updates the current descriptive step (e.g., 'Executing tool...').
  void updateStep(String step) {
    currentStep = step;
    sdkLogger.debug('State step updated: $step', tag: 'STATE');
    notifyListeners();
  }

  /// Mark the run as completed successfully.
  /// Finalizes the state following a successful run.
  void completeRun() {
    isRunning = false;
    currentStep = 'Run completed';
    sdkLogger.info('Agent run completed successfully', tag: 'STATE');
    notifyListeners();
  }

  /// Mark the run as failed with an error.
  /// Records a failure and preserves the error message for display.
  void failRun(String error) {
    isRunning = false;
    errorMessage = error;
    currentStep = 'Run failed';
    sdkLogger.error('Agent run failed: $error', tag: 'STATE');
    notifyListeners();
  }

  /// Reset the state to idle.
  void reset() {
    isRunning = false;
    currentStep = '';
    errorMessage = null;
    sdkLogger.info('State reset to idle', tag: 'STATE');
    notifyListeners();
  }
}

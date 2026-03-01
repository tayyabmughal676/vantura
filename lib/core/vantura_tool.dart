/// Abstract base class for Vantura tools that can be used by the agent.
///
/// Tools provide functionality for the agent to perform specific tasks,
/// such as calculations, network checks, or API testing.
///
/// [T] represents the type of arguments this tool accepts.
abstract class VanturaTool<T> {
  /// The name of the tool, used for identification in tool calls.
  String get name;

  /// A description of what the tool does, for the agent's understanding.
  String get description;

  /// JSON Schema describing the parameters this tool accepts.
  Map<String, dynamic> get parameters;

  /// Whether this tool normally requires human confirmation before execution.
  /// If you need dynamic confirmation logic based on the arguments, override
  /// [requiresConfirmationFor] instead.
  bool get requiresConfirmation => false;

  /// Dynamic evaluation of whether this specific execution requires confirmation.
  /// By default, this simply returns [requiresConfirmation]. Override this to
  /// skip confirmation for low-risk operations (e.g., deleting a trivial resource).
  bool requiresConfirmationFor(T args) => requiresConfirmation;

  /// Maximum time this tool is allowed to run before being cancelled.
  /// Defaults to 30 seconds.
  Duration get timeout => const Duration(seconds: 30);

  /// Parses the JSON arguments into the typed arguments object.
  ///
  /// This method is called by the agent to convert the raw JSON arguments
  /// from the LLM into the structured [T] type.
  T parseArgs(Map<String, dynamic> json);

  /// Executes the tool with the given arguments.
  ///
  /// Returns the result as a string. Implementations should handle
  /// validation of [args] and throw exceptions for invalid inputs.
  ///
  /// [args] should be of type [T], which represents the structured arguments
  /// for this tool.
  Future<String> execute(T args);
}

/// Represents null arguments for tools that don't take any parameters.
class NullArgs {
  const NullArgs();
}

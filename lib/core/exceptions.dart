/// Base class for all exceptions thrown by the Vantura SDK.
sealed class VanturaException implements Exception {
  /// A human-readable message describing the error.
  final String message;

  /// The original error that caused this exception, if any.
  final Object? originalError;

  /// Creates a [VanturaException] with the specified [message] and optional [originalError].
  VanturaException(this.message, {this.originalError});

  @override
  String toString() => 'VanturaException: $message';
}

/// Thrown when the Vantura API returns an error response.
class VanturaApiException extends VanturaException {
  /// The HTTP status code returned by the API.
  final int? statusCode;

  /// The raw response body from the API.
  final String? responseBody;

  /// Creates a [VanturaApiException] with status code and optional response body.
  VanturaApiException(
    super.message, {
    this.statusCode,
    this.responseBody,
    super.originalError,
  });

  @override
  String toString() =>
      'VanturaApiException ($statusCode): $message\nBody: $responseBody';
}

/// Thrown when the agent hits an API rate limit (HTTP 429).
class VanturaRateLimitException extends VanturaApiException {
  /// Creates a [VanturaRateLimitException].
  VanturaRateLimitException(
    super.message, {
    super.statusCode = 429,
    super.responseBody,
  });
}

/// Thrown when a tool execution fails.
class VanturaToolException extends VanturaException {
  /// The name of the tool that failed.
  final String toolName;

  /// Creates a [VanturaToolException] for the specified [toolName].
  VanturaToolException(this.toolName, super.message, {super.originalError});

  @override
  String toString() => 'VanturaToolException [$toolName]: $message';
}

/// Thrown when an operation is cancelled by the user.
class VanturaCancellationException extends VanturaException {
  /// Creates a [VanturaCancellationException].
  VanturaCancellationException([
    super.message = 'Operation was cancelled by user',
  ]);
}

/// Thrown when the agent exceeds the maximum allowed reasoning iterations.
class VanturaIterationException extends VanturaException {
  /// The maximum number of iterations that was exceeded.
  final int maxIterations;

  /// Creates a [VanturaIterationException] with the specified [maxIterations].
  VanturaIterationException(this.maxIterations)
    : super('Maximum reasoning iterations ($maxIterations) exceeded');
}

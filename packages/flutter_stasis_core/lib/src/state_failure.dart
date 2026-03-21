/// Base failure contract used by stasis command/state abstractions.
abstract class StateFailure {
  /// Creates a failure with a user-friendly [message].
  const StateFailure(this.message);

  /// Human-readable description for UI feedback.
  final String message;
}

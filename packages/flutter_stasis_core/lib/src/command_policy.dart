/// Concurrency strategy used while executing commands.
enum CommandPolicy {
  /// Runs every invocation concurrently.
  parallel,

  /// Ignores new invocations while one is in-flight for the same key.
  droppable,

  /// Queues invocations and runs one at a time for the same key.
  sequential,

  /// Keeps only the latest invocation callbacks for the same key.
  ///
  /// Previous invocations still complete, but their `onError/onSuccess`
  /// callbacks are suppressed if a newer one started.
  restartable,
}

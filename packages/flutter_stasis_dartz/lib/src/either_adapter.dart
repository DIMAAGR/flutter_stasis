import 'package:dartz/dartz.dart';
import 'package:flutter_stasis_core/flutter_stasis_core.dart';

/// Adapter command that bridges dartz Either into stasis CommandResult.
class EitherTaskCommand<F, R> implements Command<F, R> {
  /// Creates a command from [task] that resolves to `Either<F, R>`.
  const EitherTaskCommand(this.task);

  /// Task function returning dartz Either.
  final Future<Either<F, R>> Function() task;

  @override
  Future<CommandResult<F, R>> call() async {
    final output = await task();
    return output.fold(CommandFailure.new, CommandSuccess.new);
  }
}

/// Semantic adapter for use cases exposing `Future<Either<F, R>> call()`.
final class UseCaseCommand<F, R> extends EitherTaskCommand<F, R> {
  /// Creates a command from a use-case callable.
  const UseCaseCommand(super.task);
}

/// Convenience extensions for dartz integration.
extension EitherTaskToCommandX<F, R> on Future<Either<F, R>> Function() {
  /// Converts an `Either` task into a [Command].
  Command<F, R> asStasisCommand() => EitherTaskCommand<F, R>(this);
}

/// Bridges one `Either` value into [CommandResult].
extension EitherToCommandResultX<F, R> on Either<F, R> {
  /// Converts current `Either` into [CommandResult].
  CommandResult<F, R> toCommandResult() {
    return fold(CommandFailure.new, CommandSuccess.new);
  }
}

import 'command_result.dart';

/// Unit of executable work that returns [CommandResult].
abstract class Command<F, R> {
  /// Executes the command.
  Future<CommandResult<F, R>> call();
}

/// Adapts a function into a [Command].
final class TaskCommand<F, R> implements Command<F, R> {
  /// Creates a command from [task].
  const TaskCommand(this.task);

  /// Task callback.
  final Future<CommandResult<F, R>> Function() task;

  @override
  Future<CommandResult<F, R>> call() => task();
}

/// Decorates a command by mapping the successful value.
final class MappedCommand<F, I, O> implements Command<F, O> {
  /// Creates a mapped command.
  const MappedCommand({required this.command, required this.mapper});

  /// Source command.
  final Command<F, I> command;

  /// Success mapper.
  final O Function(I value) mapper;

  @override
  Future<CommandResult<F, O>> call() async {
    final output = await command();
    return output.map(mapper);
  }
}

/// Helpers for command composition.
extension CommandMapX<F, R> on Command<F, R> {
  /// Maps successful output from `R` to `S`.
  Command<F, S> map<S>(S Function(R value) mapper) {
    return MappedCommand<F, R, S>(command: this, mapper: mapper);
  }
}

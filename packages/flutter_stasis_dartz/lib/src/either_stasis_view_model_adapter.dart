import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_stasis/flutter_stasis.dart';

import 'either_adapter.dart';

/// Ergonomic bridge to run dartz use-cases directly from [StasisViewModel].
///
/// It keeps `flutter_stasis` core agnostic from dartz while providing a
/// zero-boilerplate path in view models.
extension EitherStasisViewModelX<F, S, T extends StateObject<F, S, T>>
    on StasisViewModel<F, S, T> {
  /// Executes a task that returns `Future<Either<F, R>>`.
  Future<CommandResult<F, R>> executeEither<R>({
    required Future<Either<F, R>> Function() command,
    FutureOr<void> Function(F failure)? onError,
    required FutureOr<void> Function(R result) onSuccess,
    FutureOr<void> Function()? onLoading,
    CommandPolicy policy = CommandPolicy.parallel,
    Object? policyKey,
  }) {
    return execute<R>(
      command: EitherTaskCommand<F, R>(command),
      onError: onError,
      onSuccess: onSuccess,
      onLoading: onLoading,
      policy: policy,
      policyKey: policyKey,
    );
  }

}

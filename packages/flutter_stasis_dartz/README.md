# flutter_stasis_dartz

[![pub.dev](https://img.shields.io/pub/v/flutter_stasis_dartz.svg)](https://pub.dev/packages/flutter_stasis_dartz)
[![license: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

[dartz](https://pub.dev/packages/dartz) adapter for [flutter_stasis](https://pub.dev/packages/flutter_stasis).

If your use cases return `Future<Either<Failure, T>>`, this package bridges them to `StasisViewModel` with zero boilerplate. The core package has no dependency on dartz — this adapter is completely optional.

---

## Installation

```yaml
dependencies:
  flutter_stasis: ^0.3.1
  flutter_stasis_dartz: ^0.3.1
  dartz: ^0.10.1
```

---

## Usage

Import the adapter and call `executeEither` exactly like `execute`:

```dart
import 'package:flutter_stasis_dartz/flutter_stasis_dartz.dart';

class ProjectsViewModel
    extends StasisViewModel<AppFailure, List<Project>, ProjectsState> {

  ProjectsViewModel(this._getProjects)
      : super(ProjectsState.initial());

  final GetProjectsUseCase _getProjects; // returns Future<Either<AppFailure, List<Project>>>

  // Minimal — onError falls back to setError automatically
  Future<void> load() => executeEither(
    command: _getProjects.call,
    onSuccess: setSuccess,
  );

  // With loading indicator
  Future<void> reload() => executeEither(
    command: _getProjects.call,
    onSuccess: setSuccess,
    onLoading: setLoading,
  );

  // Custom error handling
  Future<void> loadSilently() => executeEither(
    command: _getProjects.call,
    onSuccess: setSuccess,
    onError: (f) => emit(ShowSnackBarEvent(f.message)),
  );
}
```

`onSuccess` is required. `onError` is optional — defaults to `setError`. `onLoading` is optional.

`executeEither` wraps `Future<Either<F, R>>` into a `Command<F, R>` internally and delegates to `execute`.

---

## With concurrency policy

`executeEither` accepts the same `CommandPolicy` as `execute`:

```dart
Future<void> search(String query) => executeEither(
  command: () => _searchUseCase(query),
  onSuccess: setSuccess,
  onLoading: setLoading,
  policy: CommandPolicy.restartable,
  policyKey: 'search',
);
```

Use stable `policyKey` values for `droppable`, `sequential`, and `restartable`.

---

## Converting Either manually

If you need to convert an `Either` result outside of a ViewModel, use the extension:

```dart
import 'package:flutter_stasis_dartz/flutter_stasis_dartz.dart';

final either = await someUseCase();
final result = either.toCommandResult(); // CommandResult<F, R>
```

Or wrap any `Either`-returning function as a `Command`:

```dart
final command = myUseCase.call.asStatekitCommand();
// Command<F, R> — pass to execute(command: command, ...)
```

---

## How it works

`executeEither` is a plain extension method on `StasisViewModel`. It converts your function into an `EitherTaskCommand<F, R>` that implements `Command<F, R>`, then calls the existing `execute` method. No magic, no hidden state.

```dart
extension EitherStasisViewModelX<F, S, T extends StateObject<F, S, T>>
    on StasisViewModel<F, S, T> {
  Future<CommandResult<F, R>> executeEither<R>({
    required Future<Either<F, R>> Function() command,
    required FutureOr<void> Function(R result) onSuccess,
    FutureOr<void> Function(F failure)? onError,   // optional — defaults to setError
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
```

---

## License

MIT

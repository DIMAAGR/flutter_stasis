# flutter_stasis_core

[![pub.dev](https://img.shields.io/pub/v/flutter_stasis_core.svg)](https://pub.dev/packages/flutter_stasis_core)
[![license: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

Pure Dart core of the [Stasis](https://pub.dev/packages/flutter_stasis) ecosystem.

No Flutter dependency. No third-party result type. Just the contracts that power everything else.

---

## What's in this package

| Class | Description |
|---|---|
| `ViewModelState<F, S>` | Sealed lifecycle — `InitialState`, `LoadingState`, `SuccessState`, `ErrorState` |
| `StateObject<F, S, Self>` | Base for immutable per-screen state |
| `Command<F, R>` | Contract for executable async work |
| `CommandResult<F, R>` | Sealed result — `CommandSuccess`, `CommandFailure` |
| `CommandPolicy` | Concurrency strategy — `parallel`, `droppable`, `restartable`, `sequential` |
| `CommandAction` | Executor that wires command + policy + callbacks |
| `StateFailure` | Optional base class for typed failures |

---

## ViewModelState

Four states that cover every async lifecycle — no ambiguous combinations:

```dart
sealed class ViewModelState<F, S> {
  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(S data) success,
    required T Function(F failure) error,
  });
}
```

Usage:

```dart
state.when(
  initial:  () => const SizedBox(),
  loading:  () => const CircularProgressIndicator(),
  success:  (data) => DataWidget(data),
  error:    (failure) => ErrorWidget(failure.message),
);
```

---

## StateObject

Immutable state container for a single screen. Extend it and add your own fields:

```dart
class SearchState extends StateObject<AppFailure, List<Result>, SearchState> {
  const SearchState({
    required super.state,
    this.query = '',
  });

  final String query;

  // Derive from lifecycle — never duplicate
  List<Result>? get results     => dataOrNull;
  String?       get errorMessage => failureOrNull?.message;

  @override
  SearchState withState(ViewModelState<AppFailure, List<Result>> state) =>
      copyWith(state: state);

  SearchState copyWith({
    ViewModelState<AppFailure, List<Result>>? state,
    String? query,
  }) => SearchState(
    state: state ?? this.state,
    query: query ?? this.query,
  );

  @override
  List<Object?> get props => [state, query];
}
```

Built-in getters:

```dart
state.isLoading   // true when LoadingState
state.isSuccess   // true when SuccessState
state.isError     // true when ErrorState
state.dataOrNull  // S? — non-null only when SuccessState
state.failureOrNull // F? — non-null only when ErrorState
```

---

## Command

A unit of async work that returns `CommandResult<F, R>`:

```dart
abstract class Command<F, R> {
  Future<CommandResult<F, R>> call();
}
```

Wrap any function with `TaskCommand`:

```dart
final command = TaskCommand<AppFailure, List<Project>>(
  () => repository.getAll(),
);
```

Map the success value without touching the ViewModel:

```dart
final command = TaskCommand<AppFailure, List<ProjectEntity>>(
  () => repository.getAll(),
).map((entities) => entities.map(ProjectCard.fromEntity).toList());
```

---

## CommandResult

```dart
final result = await command();

result.fold(
  onFailure: (failure) => print('Error: ${failure.message}'),
  onSuccess: (data)    => print('Got ${data.length} items'),
);

// Or use the accessors
final data    = result.resultOrNull;
final failure = result.failureOrNull;
```

---

## CommandPolicy

Control concurrency per execution:

```dart
await CommandAction.execute(
  command: searchCommand,
  onLoading: ...,
  onError: ...,
  onSuccess: ...,
  policy: CommandPolicy.restartable, // cancels previous on new call
);
```

| Policy | Behaviour |
|---|---|
| `parallel` *(default)* | Every call runs independently |
| `droppable` | Ignores new calls while one is in-flight |
| `restartable` | Keeps only the latest call's callbacks |
| `sequential` | Queues calls, runs one at a time |

---

## This package is framework-agnostic

`flutter_stasis_core` has no Flutter SDK dependency and no opinion on how results are produced. It works with plain `Future`, with dartz `Either`, with `fpdart`, or any other style via adapters.

If you want Flutter widgets and the full ViewModel base class, add [`flutter_stasis`](https://pub.dev/packages/flutter_stasis).

---

## License

MIT
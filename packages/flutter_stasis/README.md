# flutter_stasis

[![pub.dev](https://img.shields.io/pub/v/flutter_stasis.svg)](https://pub.dev/packages/flutter_stasis)
[![license: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

Flutter layer of the Stasis ecosystem. Provides `StasisViewModel`, reactive widgets, and ephemeral UI events.

> For the pure-Dart contracts (`StateObject`, `Command`, `CommandPolicy`) see [`flutter_stasis_core`](https://pub.dev/packages/flutter_stasis_core).
> For dartz `Either` integration see [`flutter_stasis_dartz`](https://pub.dev/packages/flutter_stasis_dartz).

---

## Installation

```yaml
dependencies:
  flutter_stasis: ^0.2.0
```

---

## StasisViewModel

Base class for all ViewModels. Requires an initial `StateObject` and exposes helpers to transition lifecycle and execute async commands.

```dart
class ProjectsViewModel
    extends StasisViewModel<AppFailure, List<Project>, ProjectsState> {

  ProjectsViewModel(this._getProjects)
      : super(ProjectsState.initial());

  final GetProjectsUseCase _getProjects;

  Future<void> load() => execute(
    command: _getProjects,
    onLoading: setLoading,
    onError: setError,
    onSuccess: setSuccess,
  );

  void setFilter(ProjectFilter f) =>
      update((s) => s.copyWith(filter: f));
}
```

### State helpers

```dart
setLoading()                         // → LoadingState
setSuccess(data)                     // → SuccessState(data)
setError(failure)                    // → ErrorState(failure)
setInitialState()                    // → InitialState
update((s) => s.copyWith(...))       // update fields, keep lifecycle
```

Combine lifecycle transition + field update in one call with `withUpdate`:

```dart
setSuccess(
  audioFile,
  withUpdate: (s) => s.copyWith(waveform: audioFile.waveform),
);
```

> `setError` is the automatic fallback for `execute` when `onError` is not provided.

### execute

Single entry point for all async actions.

`onSuccess` is required — you must decide what to do with the result.  
`onError` is optional — when omitted, `setError` is called automatically.  
`onLoading` is optional — pass `setLoading` when you want a loading indicator.

```dart
// Full form
Future<void> load() => execute(
  command: _getProjects,
  onSuccess: setSuccess,
  onError: setError,    // optional, this is the default behaviour
  onLoading: setLoading,
);

// Minimal — onError falls back to setError automatically
Future<void> load() => execute(
  command: _getProjects,
  onSuccess: setSuccess,
);

// Custom error handling — override the default
Future<void> load() => execute(
  command: _getProjects,
  onSuccess: setSuccess,
  onError: (f) => emit(ShowSnackBarEvent(f.message)),
);

// With concurrency policy
Future<void> search(String query) => execute(
  command: TaskCommand(() => _searchUseCase(query)),
  onSuccess: setSuccess,
  onLoading: setLoading,
  policy: CommandPolicy.restartable,
);
```

See [`flutter_stasis_core`](https://pub.dev/packages/flutter_stasis_core) for `Command`, `CommandPolicy` and result composition.

### Lifecycle

```dart
class _ScreenState extends State<MyScreen> {
  late final vm = MyViewModel(getIt());

  @override
  void dispose() {
    vm.dispose(); // clears state, events, and concurrency scope
    super.dispose();
  }
}
```

---

## StasisBuilder

Rebuilds whenever the `StateObject` changes:

```dart
StasisBuilder(
  listenable: vm.stateListenable,
  builder: (context, state, _) {
    if (state.isLoading) return const Loader();
    if (state.isError)   return ErrorBanner(state.errorMessage!);
    return ProjectList(state.projects ?? []);
  },
);
```

---

## StasisSelector

Rebuilds only when the selected value changes. Use this inside `StasisBuilder` to avoid rebuilding heavy subtrees:

```dart
// Rebuilds only when isDragging changes
StasisSelector<AudioState, bool>(
  listenable: vm.stateListenable,
  selector: (state) => state.isDragging,
  builder: (context, isDragging, _) => DropZone(active: isDragging),
);
```

Custom equality for complex types:

```dart
StasisSelector<AudioState, List<double>>(
  listenable: vm.stateListenable,
  selector: (state) => state.waveform,
  equals: (a, b) => a.length == b.length,
  builder: (context, waveform, _) => WaveformWidget(points: waveform),
);
```

---

## StasisEventListener

One-shot events that should never be stored in state — navigation, snackbars, dialogs.

The ViewModel dispatches; the View reacts:

```dart
// Define your events
final class ShowSnackBarEvent extends UiEvent {
  const ShowSnackBarEvent(this.message);
  final String message;
}

final class PopEvent extends UiEvent {
  const PopEvent();
}
```

```dart
// ViewModel dispatches
void onSaved() {
  emit(const ShowSnackBarEvent('Saved successfully'));
  emit(const PopEvent());
}
```

```dart
// View reacts
StasisEventListener(
  stream: vm.events,
  onEvent: (context, event) async {
    switch (event) {
      case ShowSnackBarEvent(:final message):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      case PopEvent():
        Navigator.of(context).pop();
    }
  },
  child: ...,
);
```

---

## Full example

```dart
// state
class CounterState extends StateObject<String, int, CounterState> {
  const CounterState({required super.state});

  int get count => dataOrNull ?? 0;

  @override
  CounterState withState(ViewModelState<String, int> state) =>
      CounterState(state: state);

  @override
  List<Object?> get props => [state];
}

// view model
class CounterViewModel extends StasisViewModel<String, int, CounterState> {
  CounterViewModel()
      : super(const CounterState(state: SuccessState(0)));

  Future<void> increment() => execute(
    command: TaskCommand(() async {
      await Future.delayed(const Duration(milliseconds: 200));
      return CommandSuccess((state.count) + 1);
    }),
    onSuccess: setSuccess,
    onLoading: setLoading,
    policy: CommandPolicy.droppable,
  );
}

// screen
class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  final vm = CounterViewModel();

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: StasisBuilder(
        listenable: vm.stateListenable,
        builder: (_, state, __) => state.isLoading
            ? const CircularProgressIndicator()
            : Text('${state.count}', style: const TextStyle(fontSize: 48)),
      ),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: vm.increment,
      child: const Icon(Icons.add),
    ),
  );
}
```

## Usage patterns

Stasis works regardless of how your use cases return results. Pick the pattern that fits your project.

---

### Pattern 1 — Use case with dartz + adapter installed

The most ergonomic path if you already use dartz. Import `flutter_stasis_dartz` and call `executeEither` directly with your use case.

```dart
// use case (your domain layer — untouched)
class GetProjectsUseCase {
  GetProjectsUseCase(this._repository);
  final ProjectRepository _repository;

  Future<Either<AppFailure, List<Project>>> call() =>
      _repository.getAll();
}
```

```dart
// view model
import 'package:flutter_stasis_dartz/flutter_stasis_dartz.dart';

class ProjectsViewModel
    extends StasisViewModel<AppFailure, List<Project>, ProjectsState> {

  ProjectsViewModel(this._getProjects) : super(ProjectsState.initial());

  final GetProjectsUseCase _getProjects;

  Future<void> load() => executeEither(
    command: _getProjects.call,
    onSuccess: setSuccess,         // onError omitted → setError called automatically
    onLoading: setLoading,
  );
}
```

---

### Pattern 2 — Use case with dartz, no adapter

If you use dartz but don't want to add `flutter_stasis_dartz`, convert the `Either` manually inside a `TaskCommand`. One extra line, no extra dependency.

```dart
// use case (same as above)
class GetProjectsUseCase {
  Future<Either<AppFailure, List<Project>>> call() =>
      _repository.getAll();
}
```

```dart
// view model — no adapter import needed
class ProjectsViewModel
    extends StasisViewModel<AppFailure, List<Project>, ProjectsState> {

  ProjectsViewModel(this._getProjects) : super(ProjectsState.initial());

  final GetProjectsUseCase _getProjects;

  Future<void> load() => execute(
    command: TaskCommand(() async {
      final result = await _getProjects();
      return result.fold(
        (failure) => CommandFailure(failure),
        (data)    => CommandSuccess(data),
      );
    }),
    onSuccess: setSuccess,         // onError omitted → setError called automatically
    onLoading: setLoading,
  );
}
```

---

### Pattern 3 — No dartz, no adapter

Use cases return plain `Future` and throw on failure, or you catch errors yourself. Wrap everything in a `TaskCommand` and return `CommandSuccess` / `CommandFailure` directly.

```dart
// use case — plain Future, throws on error
class GetProjectsUseCase {
  Future<List<Project>> call() => _repository.getAll();
}
```

```dart
// view model
class ProjectsViewModel
    extends StasisViewModel<AppFailure, List<Project>, ProjectsState> {

  ProjectsViewModel(this._getProjects) : super(ProjectsState.initial());

  final GetProjectsUseCase _getProjects;

  Future<void> load() => execute(
    command: TaskCommand(() async {
      try {
        final data = await _getProjects();
        return CommandSuccess(data);
      } on NetworkException catch (e) {
        return CommandFailure(AppFailure(e.message));
      } catch (e) {
        return CommandFailure(AppFailure('Unexpected error'));
      }
    }),
    onSuccess: setSuccess,         // onError omitted → setError called automatically
    onLoading: setLoading,
  );
}
```

Alternatively, if you want the use case to already speak `CommandResult`, implement `Command<F, R>` directly — then pass it straight to `execute` with no wrapper:

```dart
// use case implements Command directly
class GetProjectsUseCase implements Command<AppFailure, List<Project>> {
  @override
  Future<CommandResult<AppFailure, List<Project>>> call() async {
    try {
      final data = await _repository.getAll();
      return CommandSuccess(data);
    } on NetworkException catch (e) {
      return CommandFailure(AppFailure(e.message));
    }
  }
}
```

```dart
// view model — cleanest form, no wrapper, no onError needed
Future<void> load() => execute(
  command: _getProjects,    // use case IS the command
  onSuccess: setSuccess,
);
```

## 0.2.0 update

Based on community feedback, `flutter_stasis` now includes a dedicated runtime notifier:

- `StasisNotifier<T>` (internal runtime for state updates)
- `invalidate()` on `StasisViewModel` (notify without replacing state instance)
- `batch()` on `StasisViewModel` (coalesce multiple updates into a single notification)

Why this matters:

- keeps immutable update flow (`update`, `copyWith`, lifecycle helpers)
- unlocks advanced controlled scenarios where internal mutable data changes but state object replacement is unnecessary
- reduces noisy rebuild bursts when multiple updates happen together

---

## FAQ from Reddit feedback

### "Can I do this with sealed classes in BLoC/Riverpod too?"

Yes. Stasis does not claim this is impossible elsewhere.

The goal is to make the lifecycle (`Initial/Loading/Success/Error`) structural and always present in the base contracts, so teams start from a consistent baseline without re-deciding the pattern per feature.

### "Data + loading at the same time is normal (refresh/lazy load)."

Correct. A common pattern is to keep existing data visible while background refresh runs.

In Stasis, one explicit approach is:

```dart
Future<void> refresh() => execute(
  command: _getItems,
  onLoading: () => update((s) => s.copyWith(isRefreshing: true)),
  onSuccess: (data) => setSuccess(
    data,
    withUpdate: (s) => s.copyWith(isRefreshing: false),
  ),
  onError: (f) => setError(
    f,
    withUpdate: (s) => s.copyWith(isRefreshing: false),
  ),
);
```

This keeps the lifecycle explicit and keeps previous data visible.

### "Isn't this two loading states?"

It is two different UX intents:

- initial load (no data yet)
- background refresh (data already visible)

If your screen does not need that distinction, just use `setLoading()` and skip `isRefreshing`.

### "Why events outside state?"

You can store events in state, but then you need a consume/reset protocol.

Keeping ephemeral effects in `UiEvent` stream avoids accidental re-fire on rebuild (navigation, snackbars, dialogs).

### "Should I migrate an already stable BLoC/Riverpod codebase?"

Usually no.

Stasis is a better fit for greenfield projects or teams that want this specific trade-off from day one.

### "Codegen-free forever?"

Core design is currently codegen-free. Optional tooling can be explored later if it improves large-scale ergonomics without making codegen mandatory.

---

## Additional examples (new APIs)

### Coalesce multiple updates with `batch()`

```dart
void prepareSync() {
  batch(() {
    setLoading();
    update((s) => s.copyWith(progress: 0, isSyncing: true));
  });
}
```

### Notify listeners without replacing state via `invalidate()`

```dart
class AudioVm extends StasisViewModel<AppFailure, AudioData, AudioState> {
  AudioVm() : super(const AudioState(state: InitialState()));

  final List<double> waveformCache = <double>[];

  void patchWaveform(List<double> chunk) {
    waveformCache.addAll(chunk);
    invalidate();
  }
}
```

### Explicit command keying for concurrency

```dart
Future<void> toggleItem(String id) => execute(
  command: TaskCommand(() => _toggleUseCase(id)),
  onSuccess: (_) => load(),
  policy: CommandPolicy.restartable,
  policyKey: 'toggle_$id',
);
```

---

## Roadmap focus (short term)

Near-term priorities, based on real feedback:

1. keep lifecycle semantics explicit and predictable
2. refine async UX patterns in docs (initial load vs refresh)
3. evolve controlled mutable-resource story on top of `invalidate()`
4. continue improving examples and test ergonomics

---

## License

MIT

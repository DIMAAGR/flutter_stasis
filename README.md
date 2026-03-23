# flutter_stasis

[![license: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

State management for Flutter built around three ideas: **explicit lifecycle**, **standardised async execution**, and **ephemeral UI events**.

One ViewModel. One StateObject. No boilerplate.

---

## Packages

| Package | Version | Description |
|---|---|---|
| [`flutter_stasis_core`](packages/flutter_stasis_core) | [![pub](https://img.shields.io/pub/v/flutter_stasis_core.svg)](https://pub.dev/packages/flutter_stasis_core) | Pure Dart core — `StateObject`, `ViewModelState`, `Command`, `CommandPolicy` |
| [`flutter_stasis`](packages/flutter_stasis) | [![pub](https://img.shields.io/pub/v/flutter_stasis.svg)](https://pub.dev/packages/flutter_stasis) | Flutter layer — `StasisViewModel`, `StasisBuilder`, `StasisSelector`, `StasisEventListener` |
| [`flutter_stasis_dartz`](packages/flutter_stasis_dartz) | [![pub](https://img.shields.io/pub/v/flutter_stasis_dartz.svg)](https://pub.dev/packages/flutter_stasis_dartz) | Optional dartz `Either` adapter |
| [`flutter_stasis_test`](packages/flutter_stasis_test) | [![pub](https://img.shields.io/pub/v/flutter_stasis_test.svg)](https://pub.dev/packages/flutter_stasis_test) | Test helpers |

---

## The problem

Every Flutter app needs to handle the same three async states. Over and over.

```dart
// The usual way — scattered, inconsistent, error-prone
bool isLoading = false;
List<Project>? data;
String? error;

Future<void> load() async {
  isLoading = true;
  notifyListeners();
  try {
    data = await repository.getAll();
  } catch (e) {
    error = e.toString();
  } finally {
    isLoading = false;
    notifyListeners();
  }
}
```

With Stasis:

```dart
Future<void> load() => execute(
  command: _getProjects,
  onSuccess: setSuccess,
  onLoading: setLoading,
);
```

No try/catch. No manual flags. No state that can be `isLoading: true` and `data: [...]` at the same time.

---

## Quick start

```yaml
dependencies:
  flutter_stasis: ^0.2.0
```

**1. Define your state**

```dart
class ProjectsState extends StateObject<AppFailure, List<Project>, ProjectsState> {
  const ProjectsState({required super.state, this.filter = Filter.all});

  final Filter filter;

  List<Project>? get projects    => dataOrNull;
  String?        get errorMessage => failureOrNull?.message;

  @override
  ProjectsState withState(ViewModelState<AppFailure, List<Project>> state) =>
      copyWith(state: state);

  ProjectsState copyWith({...}) => ...;

  @override
  List<Object?> get props => [state, filter];
}
```

**2. Write your ViewModel**

```dart
class ProjectsViewModel
    extends StasisViewModel<AppFailure, List<Project>, ProjectsState> {

  ProjectsViewModel(this._getProjects) : super(ProjectsState.initial());

  final GetProjectsUseCase _getProjects;

  Future<void> load() => execute(
    command: _getProjects,
    onSuccess: setSuccess,
    onLoading: setLoading,
    // onError omitted → setError is called automatically
  );

  void setFilter(Filter f) => update((s) => s.copyWith(filter: f));
}
```

**3. Build your UI**

```dart
class _ScreenState extends State<ProjectsScreen> {
  late final vm = ProjectsViewModel(getIt());

  @override
  void initState() {
    super.initState();
    vm.load();
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StasisBuilder(
      listenable: vm.stateListenable,
      builder: (context, state, _) {
        if (state.isLoading) return const Loader();
        if (state.isError)   return ErrorBanner(state.errorMessage!);
        return ProjectList(state.projects ?? []);
      },
    );
  }
}
```

---

## Key features

### Explicit lifecycle — no ambiguous state

Four states, sealed and exhaustive. The compiler forces you to handle all of them:

```dart
state.state.when(
  initial:  () => WelcomeWidget(),
  loading:  () => CircularProgressIndicator(),
  success:  (data) => DataWidget(data),
  error:    (failure) => ErrorWidget(failure.message),
);
```

### Ephemeral UI events — navigation and snackbars out of state

```dart
// ViewModel dispatches
void onSaved() {
  emit(const ShowSnackBarEvent('Saved'));
  emit(const NavigateHomeEvent());
}

// View reacts
StasisEventListener(
  stream: vm.events,
  onEvent: (context, event) async {
    switch (event) {
      case ShowSnackBarEvent(:final message):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      case NavigateHomeEvent():
        Navigator.of(context).pushReplacementNamed('/home');
    }
  },
  child: ...,
);
```

### Granular rebuilds with StasisSelector

```dart
StasisSelector<AudioState, bool>(
  listenable: vm.stateListenable,
  selector: (state) => state.isDragging,
  builder: (context, isDragging, _) => DropZone(active: isDragging),
);
```

### Race conditions handled declaratively

```dart
// Ignore double-taps
Future<void> submit() => execute(
  command: _submitUseCase,
  onSuccess: setSuccess,
  policy: CommandPolicy.droppable,
);

// Cancel previous, run latest (live search)
Future<void> search(String q) => execute(
  command: TaskCommand(() => _searchUseCase(q)),
  onSuccess: setSuccess,
  policy: CommandPolicy.restartable,
);
```

### Works with dartz — or without it

```dart
// With flutter_stasis_dartz
Future<void> load() => executeEither(
  command: _getProjects.call,   // Future<Either<Failure, List<Project>>>
  onSuccess: setSuccess,
);

// Without dartz — plain Future
Future<void> load() => execute(
  command: TaskCommand(() async {
    try {
      return CommandSuccess(await _getProjects());
    } on NetworkException catch (e) {
      return CommandFailure(AppFailure(e.message));
    }
  }),
  onSuccess: setSuccess,
);
```

---

## Example app

A fully working task manager app is in [`example/`](example). It demonstrates:

- `StasisViewModel` + `StateObject`
- `execute` with all four `CommandPolicy` variants
- `StasisBuilder` for full-screen rebuilds
- `StasisSelector` for granular rebuilds
- `StasisEventListener` for snackbars and dialogs
- `UiEvent` typed events
- Optimistic updates with rollback
- Unit tests with `flutter_stasis_test`

```bash
cd example
flutter pub get
flutter run
```

---

## Compared to the alternatives

|  | BLoC | Riverpod | **Stasis** |
|---|---|---|---|
| Files per feature | 3+ | 1–2 | 2 |
| Code generation | Optional | Optional | None |
| Async lifecycle | Manual | `AsyncValue` | `execute` |
| Ephemeral events | Via stream | `ref.listen` | `UiEvent` |
| Granular rebuilds | `buildWhen` | `select` | `StasisSelector` |
| Race conditions | `bloc_concurrency` | Manual | `CommandPolicy` |
| dartz adapter | ❌ | ❌ | ✅ |

---

## Repository structure

```
flutter_stasis/
├── packages/
│   ├── flutter_stasis_core/    # Pure Dart
│   ├── flutter_stasis/         # Flutter layer
│   ├── flutter_stasis_dartz/   # dartz adapter
│   └── flutter_stasis_test/    # Test helpers
├── example/                    # Example app
└── README.md
```

---

## License

MIT — see [LICENSE](LICENSE).

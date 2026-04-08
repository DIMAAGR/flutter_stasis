# flutter_stasis_test

[![pub.dev](https://img.shields.io/pub/v/flutter_stasis_test.svg)](https://pub.dev/packages/flutter_stasis_test)
[![license: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

Test helpers for [flutter_stasis](https://pub.dev/packages/flutter_stasis).

---

## Installation

```yaml
dev_dependencies:
  flutter_stasis_test: ^0.4.0
  flutter_test:
    sdk: flutter
```

---

## Why

Testing a `StasisViewModel` is straightforward — call a method, check the state. But writing the capture/assertion loop manually gets repetitive:

```dart
// Without helpers — repeated in every test file
final states = <MyState>[];
vm.stateListenable.addListener(() => states.add(vm.state));
await vm.load();
expect(states[0].isLoading, isTrue);
expect(states[1].projects, hasLength(3));
```

With `flutter_stasis_test`:

```dart
await assertStateSequence(
  listenable: vm.stateListenable,
  act: vm.load,
  expected: [
    (s) => s.isLoading,
    (s) => s.projects?.length == 3,
  ],
  includeInitial: false,
);
```

---

## captureStates

Collects all state values emitted while `act` runs:

```dart
final states = await captureStates(
  listenable: vm.stateListenable,
  act: vm.load,
  includeInitial: true, // include the state before act runs (default: true)
);

expect(states, hasLength(3));       // initial + loading + success
expect(states[1].isLoading, isTrue);
expect(states[2].projects, isNotEmpty);
```

---

## captureEvents

Collects all `UiEvent`s emitted while `act` runs:

```dart
final events = await captureEvents(
  stream: vm.events,
  act: vm.save,
);

expect(events, [isA<ShowSnackBarEvent>(), isA<PopEvent>()]);
```

---

## assertStateSequence

Captures states and asserts each one with a predicate. Fails with a descriptive message if the length or any predicate doesn't match:

```dart
await assertStateSequence(
  listenable: vm.stateListenable,
  act: vm.load,
  expected: [
    (s) => s.isLoading,
    (s) => s.projects?.length == 3,
  ],
  includeInitial: false,
);
```

Using `equalsValue` for simple equality:

```dart
await assertStateSequence(
  listenable: vm.stateListenable,
  act: vm.setFilter,
  expected: [
    equalsValue(ProjectsState(filter: ProjectFilter.active, ...)),
  ],
  includeInitial: false,
);
```

---

## assertEventSequence

Same as `assertStateSequence` but for events:

```dart
await assertEventSequence(
  stream: vm.events,
  act: vm.onSavePressed,
  expected: [
    (e) => e is ShowSnackBarEvent && e.message == 'Saved',
    (e) => e is NavigateToEvent,
  ],
);
```

---

## Full test example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_stasis_test/flutter_stasis_test.dart';

void main() {
  late ProjectsViewModel vm;
  late MockGetProjectsUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockGetProjectsUseCase();
    vm = ProjectsViewModel(mockUseCase);
  });

  tearDown(() => vm.dispose());

  test('load emits loading then success', () async {
    final fakeProjects = [Project(id: '1', name: 'Test')];
    when(() => mockUseCase.call()).thenAnswer(
      (_) async => Right(fakeProjects),
    );

    await assertStateSequence(
      listenable: vm.stateListenable,
      act: vm.load,
      expected: [
        (s) => s.isLoading,
        (s) => s.projects == fakeProjects,
      ],
      includeInitial: false,
    );
  });

  test('load emits error on failure', () async {
    when(() => mockUseCase.call()).thenAnswer(
      (_) async => Left(AppFailure('Network error')),
    );

    await assertStateSequence(
      listenable: vm.stateListenable,
      act: vm.load,
      expected: [
        (s) => s.isLoading,
        (s) => s.errorMessage == 'Network error',
      ],
      includeInitial: false,
    );
  });

  test('save emits snackbar event then navigates', () async {
    await assertEventSequence(
      stream: vm.events,
      act: vm.save,
      expected: [
        (e) => e is ShowSnackBarEvent,
        (e) => e is NavigateToEvent,
      ],
    );
  });
}
```

---

## settle parameter

If your command involves microtasks or delayed work, use `settle` to wait before collecting:

```dart
await assertStateSequence(
  listenable: vm.stateListenable,
  act: vm.loadWithDebounce,
  expected: [...],
  settle: const Duration(milliseconds: 500),
);
```

---

## License

MIT

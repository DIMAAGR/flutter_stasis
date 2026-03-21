import 'package:flutter/foundation.dart';

import 'stasis_probe.dart';

typedef StasisPredicate<T> = bool Function(T value);

/// Predicate helper that checks equality.
StasisPredicate<T> equalsValue<T>(T expected) => (value) => value == expected;

/// Asserts a sequence emitted by [listenable] while [act] runs.
Future<void> assertStateSequence<T>({
  required ValueListenable<T> listenable,
  required Future<void> Function() act,
  required List<StasisPredicate<T>> expected,
  bool includeInitial = true,
  Duration settle = Duration.zero,
}) async {
  final states = await captureStates<T>(
    listenable: listenable,
    act: act,
    includeInitial: includeInitial,
    settle: settle,
  );
  _assertSequence(values: states, predicates: expected, label: 'state');
}

/// Asserts events emitted by [stream] while [act] runs.
Future<void> assertEventSequence<T>({
  required Stream<T> stream,
  required Future<void> Function() act,
  required List<StasisPredicate<T>> expected,
  Duration settle = Duration.zero,
}) async {
  final events = await captureEvents<T>(stream: stream, act: act, settle: settle);
  _assertSequence(values: events, predicates: expected, label: 'event');
}

void _assertSequence<T>({
  required List<T> values,
  required List<StasisPredicate<T>> predicates,
  required String label,
}) {
  if (values.length != predicates.length) {
    throw StateError(
      'Unexpected $label sequence length. '
      'Expected ${predicates.length}, got ${values.length}. '
      'Values: $values',
    );
  }

  for (var i = 0; i < predicates.length; i++) {
    final accepted = predicates[i](values[i]);
    if (!accepted) {
      throw StateError(
        'Unexpected $label at index $i. '
        'Value: ${values[i]}. '
        'Sequence: $values',
      );
    }
  }
}

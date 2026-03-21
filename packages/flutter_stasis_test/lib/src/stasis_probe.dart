import 'dart:async';

import 'package:flutter/foundation.dart';

/// Captures all values emitted by a [ValueListenable] while [act] runs.
Future<List<T>> captureStates<T>({
  required ValueListenable<T> listenable,
  required Future<void> Function() act,
  bool includeInitial = true,
  Duration settle = Duration.zero,
}) async {
  final values = <T>[];
  if (includeInitial) values.add(listenable.value);

  void onState() => values.add(listenable.value);

  listenable.addListener(onState);
  try {
    await act();
    if (settle > Duration.zero) {
      await Future<void>.delayed(settle);
    }
  } finally {
    listenable.removeListener(onState);
  }

  return values;
}

/// Captures all events emitted by a [Stream] while [act] runs.
Future<List<T>> captureEvents<T>({
  required Stream<T> stream,
  required Future<void> Function() act,
  Duration settle = Duration.zero,
}) async {
  final values = <T>[];
  final sub = stream.listen(values.add);
  try {
    await act();
    if (settle > Duration.zero) {
      await Future<void>.delayed(settle);
    }
  } finally {
    await sub.cancel();
  }

  return values;
}


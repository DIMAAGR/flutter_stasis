import 'dart:async';

import 'package:flutter_stasis_core/flutter_stasis_core.dart';
import 'package:test/test.dart';

void main() {
  group('CommandAction', () {
    test('requires policyKey in debug for key-based policies', () {
      final command = TaskCommand<String, int>(
        () async => const CommandSuccess(1),
      );

      for (final policy in <CommandPolicy>[
        CommandPolicy.droppable,
        CommandPolicy.sequential,
        CommandPolicy.restartable,
      ]) {
        expect(
          () => CommandAction.execute<String, int>(
            command: command,
            onError: (_) {},
            onSuccess: (_) {},
            policy: policy,
          ),
          throwsA(isA<AssertionError>()),
        );
      }
    });

    test(
      'droppable reuses in-flight future and skips second callbacks',
      () async {
        var executions = 0;
        var firstCallbacks = 0;
        var secondCallbacks = 0;

        final command = TaskCommand<String, int>(() async {
          executions++;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return const CommandSuccess(7);
        });

        final first = CommandAction.execute<String, int>(
          command: command,
          onError: (_) {},
          onSuccess: (_) => firstCallbacks++,
          policy: CommandPolicy.droppable,
          policyKey: 'save',
        );

        final second = CommandAction.execute<String, int>(
          command: command,
          onError: (_) {},
          onSuccess: (_) => secondCallbacks++,
          policy: CommandPolicy.droppable,
          policyKey: 'save',
        );

        expect(identical(first, second), isTrue);

        final result = await second;
        expect(result.resultOrNull, 7);
        expect(executions, 1);
        expect(firstCallbacks, 1);
        expect(secondCallbacks, 0);
      },
    );

    test('restartable suppresses stale callbacks but keeps results', () async {
      final firstResult = Completer<CommandResult<String, int>>();
      final callbacks = <String>[];

      final first = CommandAction.execute<String, int>(
        command: TaskCommand(() => firstResult.future),
        onError: (_) {},
        onSuccess: (value) => callbacks.add('first:$value'),
        policy: CommandPolicy.restartable,
        policyKey: 'search',
      );

      final second = CommandAction.execute<String, int>(
        command: TaskCommand(() async => const CommandSuccess(2)),
        onError: (_) {},
        onSuccess: (value) => callbacks.add('second:$value'),
        policy: CommandPolicy.restartable,
        policyKey: 'search',
      );

      final secondOutput = await second;
      firstResult.complete(const CommandSuccess(1));
      final firstOutput = await first;

      expect(secondOutput.resultOrNull, 2);
      expect(firstOutput.resultOrNull, 1);
      expect(callbacks, ['second:2']);
    });

    test('throws fail-fast contract error when command throws', () async {
      final command = TaskCommand<String, int>(() async {
        throw StateError('boom');
      });

      await expectLater(
        CommandAction.execute<String, int>(
          command: command,
          onError: (_) {},
          onSuccess: (_) {},
        ),
        throwsA(
          isA<CommandContractViolationError>().having(
            (error) => error.originalError.toString(),
            'originalError',
            contains('boom'),
          ),
        ),
      );
    });
  });
}

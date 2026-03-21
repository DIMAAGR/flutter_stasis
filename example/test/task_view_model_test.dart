import 'package:flutter_stasis_test/flutter_stasis_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_stasis_example/features/tasks/domain/use_cases/task_use_cases.dart';
import 'package:flutter_stasis_example/features/tasks/presentation/events/task_events.dart';
import 'package:flutter_stasis_example/features/tasks/presentation/view_model/task_state.dart';
import 'package:flutter_stasis_example/features/tasks/presentation/view_model/task_view_model.dart';

TaskViewModel _makeVm() {
  final repo = TaskRepository();
  return TaskViewModel(
    GetTasksUseCase(repo),
    AddTaskUseCase(repo),
    ToggleTaskUseCase(repo),
    DeleteTaskUseCase(repo),
    ClearCompletedUseCase(repo),
  );
}

void main() {
  group('TaskViewModel', () {
    test('load emits loading then empty success', () async {
      final vm = _makeVm();

      await assertStateSequence<TaskState>(
        listenable: vm.stateListenable,
        act: vm.load,
        expected: [
          (s) => s.isLoading,
          (s) => s.isSuccess && s.allTasks.isEmpty,
        ],
        includeInitial: false,
      );

      vm.dispose();
    });

    test('addTask adds a task and emits snackbar event', () async {
      final vm = _makeVm();
      await vm.load();

      await assertEventSequence(
        stream: vm.events,
        act: () => vm.addTask('Buy groceries'),
        expected: [
          (e) => e is ShowSnackBarEvent,
        ],
      );

      expect(vm.state.allTasks, hasLength(1));
      expect(vm.state.allTasks.first.title, 'Buy groceries');

      vm.dispose();
    });

    test('toggleTask marks task as done', () async {
      final vm = _makeVm();
      await vm.load();
      await vm.addTask('Write tests');

      final taskId = vm.state.allTasks.first.id;
      await vm.toggleTask(taskId);

      expect(vm.state.allTasks.first.isDone, isTrue);
      vm.dispose();
    });

    test('deleteTask removes task', () async {
      final vm = _makeVm();
      await vm.load();
      await vm.addTask('Task to delete');

      final taskId = vm.state.allTasks.first.id;
      await vm.deleteTask(taskId);

      expect(vm.state.allTasks, isEmpty);
      vm.dispose();
    });

    test('addTask with empty title emits error snackbar', () async {
      final vm = _makeVm();
      await vm.load();

      await assertEventSequence(
        stream: vm.events,
        act: () => vm.addTask('   '),
        expected: [
          (e) =>
              e is ShowSnackBarEvent &&
              e.message == 'Title cannot be empty.',
        ],
      );

      vm.dispose();
    });

    test('setFilter changes visible tasks', () async {
      final vm = _makeVm();
      await vm.load();
      await vm.addTask('Active task');
      await vm.addTask('Done task');

      final doneId = vm.state.allTasks.last.id;
      await vm.toggleTask(doneId);

      vm.setFilter(TaskFilter.active);
      expect(vm.state.visibleTasks, hasLength(1));
      expect(vm.state.visibleTasks.first.isDone, isFalse);

      vm.setFilter(TaskFilter.completed);
      expect(vm.state.visibleTasks, hasLength(1));
      expect(vm.state.visibleTasks.first.isDone, isTrue);

      vm.dispose();
    });
  });
}

import 'package:flutter_stasis/flutter_stasis.dart';

import '../../domain/entities/task.dart';
import '../../domain/failures/task_failure.dart';
import '../../domain/use_cases/task_use_cases.dart';
import '../events/task_events.dart';
import 'task_state.dart';

class TaskViewModel
    extends StasisViewModel<TaskFailure, List<Task>, TaskState> {
  TaskViewModel(
    this._getTasks,
    this._addTask,
    this._toggleTask,
    this._deleteTask,
    this._clearCompleted,
  ) : super(const TaskState(state: InitialState()));

  final GetTasksUseCase _getTasks;
  final AddTaskUseCase _addTask;
  final ToggleTaskUseCase _toggleTask;
  final DeleteTaskUseCase _deleteTask;
  final ClearCompletedUseCase _clearCompleted;

  // ---------------------------------------------------------------------------
  // Commands
  // ---------------------------------------------------------------------------

  /// Loads all tasks. Uses droppable to prevent duplicate calls.
  Future<void> load() => execute(
    command: _getTasks,
    onSuccess: setSuccess,
    onLoading: setLoading,
    policy: CommandPolicy.droppable,
    policyKey: 'tasks_load',
  );

  /// Adds a new task while exposing a local `isAdding` flag.
  Future<void> addTask(String title) => execute(
    command: TaskCommand(() => _addTask(title)),
    onSuccess: (task) {
      final updated = [...state.allTasks, task];
      setSuccess(updated, withUpdate: (s) => s.copyWith(isAdding: false));
      emit(const ShowSnackBarEvent('Task added'));
    },
    onError: (f) {
      setError(f, withUpdate: (s) => s.copyWith(isAdding: false));
      emit(ShowSnackBarEvent(f.message));
    },
    onLoading: () => update((s) => s.copyWith(isAdding: true)),
  );

  /// Toggles done/undone. Uses restartable so rapid taps don't stack.
  Future<void> toggleTask(String id) => execute(
    command: TaskCommand(() => _toggleTask(id)),
    onSuccess: (updated) {
      final tasks = state.allTasks
          .map((t) => t.id == updated.id ? updated : t)
          .toList();
      setSuccess(tasks);
    },
    onError: (f) => emit(ShowSnackBarEvent(f.message)),
    policy: CommandPolicy.restartable,
    policyKey: 'toggle_$id',
  );

  /// Deletes a task optimistically — removes from UI immediately.
  Future<void> deleteTask(String id) {
    final optimistic = state.allTasks.where((t) => t.id != id).toList();
    setSuccess(optimistic);

    return execute(
      command: TaskCommand(() => _deleteTask(id)),
      onSuccess: (_) => emit(const ShowSnackBarEvent('Task deleted')),
      onError: (f) {
        // Rollback on error
        load();
        emit(ShowSnackBarEvent(f.message));
      },
    );
  }

  /// Clears all completed tasks.
  Future<void> clearCompleted() => execute(
    command: TaskCommand(() => _clearCompleted()),
    onSuccess: (_) {
      final remaining = state.allTasks.where((t) => !t.isDone).toList();
      setSuccess(remaining);
      emit(const ShowSnackBarEvent('Completed tasks cleared'));
    },
    onError: (f) => emit(ShowSnackBarEvent(f.message)),
  );

  // ---------------------------------------------------------------------------
  // UI interactions
  // ---------------------------------------------------------------------------

  void setFilter(TaskFilter filter) =>
      update((s) => s.copyWith(filter: filter));

  void onAddPressed() => emit(const ShowAddTaskDialogEvent());
}

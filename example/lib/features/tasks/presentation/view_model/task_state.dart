import 'package:flutter_stasis/flutter_stasis.dart';

import '../../domain/entities/task.dart';
import '../../domain/failures/task_failure.dart';

enum TaskFilter { all, active, completed }

class TaskState extends StateObject<TaskFailure, List<Task>, TaskState> {
  const TaskState({
    required super.state,
    this.filter = TaskFilter.all,
    this.isAdding = false,
  });

  final TaskFilter filter;

  // Whether a new task is being added (separate loading from main load)
  final bool isAdding;

  // ---------------------------------------------------------------------------
  // Derived — never duplicated from lifecycle
  // ---------------------------------------------------------------------------

  List<Task> get allTasks => dataOrNull ?? [];

  List<Task> get visibleTasks => switch (filter) {
        TaskFilter.all => allTasks,
        TaskFilter.active => allTasks.where((t) => !t.isDone).toList(),
        TaskFilter.completed => allTasks.where((t) => t.isDone).toList(),
      };

  int get completedCount => allTasks.where((t) => t.isDone).length;
  int get activeCount => allTasks.where((t) => !t.isDone).length;
  bool get hasCompleted => allTasks.any((t) => t.isDone);

  String? get errorMessage => failureOrNull?.message;

  // ---------------------------------------------------------------------------
  // Boilerplate
  // ---------------------------------------------------------------------------

  @override
  TaskState withState(ViewModelState<TaskFailure, List<Task>> state) =>
      copyWith(state: state);

  TaskState copyWith({
    ViewModelState<TaskFailure, List<Task>>? state,
    TaskFilter? filter,
    bool? isAdding,
  }) {
    return TaskState(
      state: state ?? this.state,
      filter: filter ?? this.filter,
      isAdding: isAdding ?? this.isAdding,
    );
  }

  @override
  List<Object?> get props => [state, filter, isAdding];
}

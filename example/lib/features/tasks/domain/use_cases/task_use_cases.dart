import 'dart:async';

import 'package:flutter_stasis/flutter_stasis.dart';
import 'package:uuid/uuid.dart';

import '../entities/task.dart';
import '../failures/task_failure.dart';

// ---------------------------------------------------------------------------
// In-memory repository (simulates a real data source)
// ---------------------------------------------------------------------------

class TaskRepository {
  final List<Task> _tasks = [];
  static const _uuid = Uuid();

  Future<List<Task>> getAll() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return List.unmodifiable(_tasks);
  }

  Future<Task> add(String title) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final task = Task(
      id: _uuid.v4(),
      title: title,
      isDone: false,
      createdAt: DateTime.now(),
    );
    _tasks.add(task);
    return task;
  }

  Future<Task> toggle(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) throw Exception('not found');
    _tasks[index] = _tasks[index].copyWith(isDone: !_tasks[index].isDone);
    return _tasks[index];
  }

  Future<void> delete(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _tasks.removeWhere((t) => t.id == id);
  }

  Future<void> clearCompleted() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _tasks.removeWhere((t) => t.isDone);
  }
}

// ---------------------------------------------------------------------------
// Use cases — each wraps one repository call
// ---------------------------------------------------------------------------

class GetTasksUseCase implements Command<TaskFailure, List<Task>> {
  GetTasksUseCase(this._repository);
  final TaskRepository _repository;

  @override
  Future<CommandResult<TaskFailure, List<Task>>> call() async {
    try {
      final tasks = await _repository.getAll();
      return CommandSuccess(tasks);
    } catch (_) {
      return const CommandFailure(TaskFailure.unknown());
    }
  }
}

class AddTaskUseCase {
  AddTaskUseCase(this._repository);
  final TaskRepository _repository;

  Future<CommandResult<TaskFailure, Task>> call(String title) async {
    if (title.trim().isEmpty) {
      return const CommandFailure(TaskFailure.emptyTitle());
    }
    try {
      final task = await _repository.add(title.trim());
      return CommandSuccess(task);
    } catch (_) {
      return const CommandFailure(TaskFailure.unknown());
    }
  }
}

class ToggleTaskUseCase {
  ToggleTaskUseCase(this._repository);
  final TaskRepository _repository;

  Future<CommandResult<TaskFailure, Task>> call(String id) async {
    try {
      final task = await _repository.toggle(id);
      return CommandSuccess(task);
    } catch (_) {
      return const CommandFailure(TaskFailure.notFound());
    }
  }
}

class DeleteTaskUseCase {
  DeleteTaskUseCase(this._repository);
  final TaskRepository _repository;

  Future<CommandResult<TaskFailure, void>> call(String id) async {
    try {
      await _repository.delete(id);
      return const CommandSuccess(null);
    } catch (_) {
      return const CommandFailure(TaskFailure.notFound());
    }
  }
}

class ClearCompletedUseCase {
  ClearCompletedUseCase(this._repository);
  final TaskRepository _repository;

  Future<CommandResult<TaskFailure, void>> call() async {
    try {
      await _repository.clearCompleted();
      return const CommandSuccess(null);
    } catch (_) {
      return const CommandFailure(TaskFailure.unknown());
    }
  }
}

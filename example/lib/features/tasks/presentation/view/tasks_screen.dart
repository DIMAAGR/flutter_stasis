import 'package:flutter/material.dart';
import 'package:flutter_stasis/flutter_stasis.dart';

import '../events/task_events.dart';
import '../view_model/task_state.dart';
import '../view_model/task_view_model.dart';
import '../widgets/add_task_dialog.dart';
import '../widgets/task_filter_bar.dart';
import '../widgets/task_item.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, required this.viewModel});

  final TaskViewModel viewModel;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  TaskViewModel get vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    vm.load();
  }

  @override
  Widget build(BuildContext context) {
    // StasisEventListener handles one-shot events from the ViewModel.
    // Navigation, snackbars, and dialogs live here — never in state.
    return StasisEventListener(
      stream: vm.events,
      onEvent: (context, event) async {
        switch (event) {
          case ShowSnackBarEvent(:final message):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          case ShowAddTaskDialogEvent():
            final title = await showAddTaskDialog(context);
            if (title != null && title.trim().isNotEmpty) {
              await vm.addTask(title);
            }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'flutter_stasis',
            style: TextStyle(
              color: Colors.deepPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            // StasisSelector rebuilds only this button when hasCompleted changes
            StasisSelector<TaskState, bool>(
              listenable: vm.stateListenable,
              selector: (s) => s.hasCompleted,
              builder: (context, hasCompleted, _) => hasCompleted
                  ? TextButton(
                      onPressed: vm.clearCompleted,
                      child: const Text(
                        'Clear done',
                        style: TextStyle(color: Colors.deepPurple),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
        body: Column(
          children: [
            // Filter bar — rebuilds only when filter or counts change
            Container(
              color: Colors.white,
              child:
                  StasisSelector<
                    TaskState,
                    ({TaskFilter filter, int active, int completed})
                  >(
                    listenable: vm.stateListenable,
                    selector: (s) => (
                      filter: s.filter,
                      active: s.activeCount,
                      completed: s.completedCount,
                    ),
                    builder: (context, data, _) => TaskFilterBar(
                      current: data.filter,
                      onChanged: vm.setFilter,
                      activeCount: data.active,
                      completedCount: data.completed,
                    ),
                  ),
            ),

            // Task list — full rebuild when list changes
            Expanded(
              child: StasisBuilder<TaskState>(
                listenable: vm.stateListenable,
                builder: (context, state, _) {
                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.isError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 12),
                          Text(state.errorMessage ?? 'Error'),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: vm.load,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final tasks = state.visibleTasks;

                  if (tasks.isEmpty) {
                    return Center(
                      child: Text(
                        state.filter == TaskFilter.completed
                            ? 'No completed tasks yet.'
                            : 'Nothing to do. Add a task!',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 16),
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Container(
                        color: Colors.white,
                        child: TaskItem(
                          task: task,
                          onToggle: () => vm.toggleTask(task.id),
                          onDelete: () => vm.deleteTask(task.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: vm.onAddPressed,
          backgroundColor: Colors.deepPurple,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

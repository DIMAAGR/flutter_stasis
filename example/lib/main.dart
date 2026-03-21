import 'package:flutter/material.dart';

import 'features/tasks/domain/use_cases/task_use_cases.dart';
import 'features/tasks/presentation/view/tasks_screen.dart';
import 'features/tasks/presentation/view_model/task_view_model.dart';

void main() {
  runApp(const StasisExampleApp());
}

class StasisExampleApp extends StatelessWidget {
  const StasisExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_stasis example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: _Root(),
    );
  }
}

// Dependency wiring — in a real app use GetIt or similar
class _Root extends StatefulWidget {
  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  late final TaskViewModel _vm;

  @override
  void initState() {
    super.initState();
    final repo = TaskRepository();
    _vm = TaskViewModel(
      GetTasksUseCase(repo),
      AddTaskUseCase(repo),
      ToggleTaskUseCase(repo),
      DeleteTaskUseCase(repo),
      ClearCompletedUseCase(repo),
    );
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TasksScreen(viewModel: _vm);
}

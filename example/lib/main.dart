import 'package:flutter/material.dart';
import 'package:flutter_stasis_secure/flutter_stasis_secure.dart';

import 'features/auth/domain/use_cases/auth_use_cases.dart';
import 'features/auth/presentation/view/auth_runtime_screen.dart';
import 'features/auth/presentation/view_model/auth_runtime_view_model.dart';
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
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
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
  late final AuthRuntimeViewModel _authVm;

  @override
  void initState() {
    super.initState();
    final repo = TaskRepository();
    final authRepository = DemoAuthRepository();
    _vm = TaskViewModel(
      GetTasksUseCase(repo),
      AddTaskUseCase(repo),
      ToggleTaskUseCase(repo),
      DeleteTaskUseCase(repo),
      ClearCompletedUseCase(repo),
    );
    _authVm = AuthRuntimeViewModel(
      RequestOtpUseCase(authRepository),
      VerifyOtpUseCase(authRepository),
      FakeSafeDataSecureAdapter(),
    );
  }

  @override
  void dispose() {
    _vm.dispose();
    _authVm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('flutter_stasis examples')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FeatureCard(
            title: 'Task manager',
            description:
                'Classic Stasis example with explicit lifecycle, commands, '
                'selectors, events, and optimistic updates.',
            icon: Icons.checklist_rounded,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TasksScreen(viewModel: _vm),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _FeatureCard(
            title: 'SafeData runtime',
            description:
                'Password, OTP, access token, refresh token, explicit '
                'retention and secure persistence demo.',
            icon: Icons.shield_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => AuthRuntimeScreen(viewModel: _authVm),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.deepPurple),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(description),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

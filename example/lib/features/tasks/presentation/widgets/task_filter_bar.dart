import 'package:flutter/material.dart';

import '../view_model/task_state.dart';

class TaskFilterBar extends StatelessWidget {
  const TaskFilterBar({
    super.key,
    required this.current,
    required this.onChanged,
    required this.activeCount,
    required this.completedCount,
  });

  final TaskFilter current;
  final void Function(TaskFilter) onChanged;
  final int activeCount;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: TaskFilter.values.map((filter) {
        final label = switch (filter) {
          TaskFilter.all => 'All',
          TaskFilter.active => 'Active ($activeCount)',
          TaskFilter.completed => 'Done ($completedCount)',
        };
        final selected = current == filter;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selected ? Colors.deepPurple : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? Colors.deepPurple : Colors.grey,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

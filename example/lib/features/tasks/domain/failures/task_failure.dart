import 'package:flutter_stasis/flutter_stasis.dart';

class TaskFailure extends StateFailure {
  const TaskFailure(super.message);

  const TaskFailure.notFound() : super('Task not found.');
  const TaskFailure.emptyTitle() : super('Title cannot be empty.');
  const TaskFailure.unknown() : super('Something went wrong. Please try again.');
}

import 'package:flutter_stasis/flutter_stasis.dart';

final class ShowSnackBarEvent extends UiEvent {
  const ShowSnackBarEvent(this.message);
  final String message;
}

final class ShowAddTaskDialogEvent extends UiEvent {
  const ShowAddTaskDialogEvent();
}

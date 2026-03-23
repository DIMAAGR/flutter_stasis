import 'package:flutter_stasis/flutter_stasis.dart';

/// Minimal package example used by pub.dev scoring.
void main() {
  // Small no-op usage so the example validates package imports.
  final command = TaskCommand<String, int>(
    () async => CommandSuccess<String, int>(1),
  );
  command.map((value) => value + 1);
}

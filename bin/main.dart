import 'package:args/command_runner.dart';
import 'package:drtimport/move_command.dart';
import 'package:drtimport/patch_command.dart';
import 'package:drtimport/pubspec.dart';

void main(List<String> arguments) async {
  PubSpec pubSpec = PubSpec();
  await pubSpec.load();
  String version = pubSpec.version;

  CommandRunner<void> runner =
      CommandRunner("drtimport", "Dart import management, version: ${version}");

  runner.addCommand(MoveCommand());
  runner.addCommand(PatchCommand());

  await runner.run(arguments);
}

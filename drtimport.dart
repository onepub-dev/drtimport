import 'package:args/command_runner.dart';
import 'package:drtimport/move_command.dart';
import 'package:drtimport/patch_command.dart';
import 'package:drtimport/pubspec.dart';

void main(List<String> arguments) async {
  var pubSpec = PubSpec();
  await pubSpec.load();
  var version = pubSpec.version;

  var runner = CommandRunner<void>(
      'drtimport', 'Dart import management, version: ${version}');

  runner.addCommand(MoveCommand());
  runner.addCommand(PatchCommand());

  await runner.run(arguments);
}

import 'package:args/command_runner.dart';
import 'package:drtimport/move_command.dart';
import 'package:drtimport/patch_command.dart';
import 'package:drtimport/make_relative_command.dart';
import 'package:drtimport/pubspec.dart';
import 'package:drtimport/watch_command.dart';

void main(List<String> arguments) async {
  var pubSpec = PubSpec();
  await pubSpec.load();
  var version = pubSpec.version;

  var runner = CommandRunner<void>(
      'drtimport', 'Dart import management, version: ${version}');

  runner.addCommand(MoveCommand());
  runner.addCommand(MakeRelativeCommand());
  runner.addCommand(PatchCommand());
  runner.addCommand(WatchCommand());

  await runner.run(arguments);
}

/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */
import 'package:dcli/dcli.dart';

import 'package:args/command_runner.dart';
import 'package:drtimport/move_command.dart';
import 'package:drtimport/patch_command.dart';
import 'package:drtimport/watch_command.dart';
import 'package:drtimport/make_relative_command.dart';

void main(List<String> arguments) async {
  var pubSpec = DartProject.fromPath('.', search: true).pubSpec;
  var version = pubSpec.version;

  var runner = CommandRunner<void>(
      'drtimport', 'Dart import management, version: ${version}');

  runner.addCommand(MoveCommand());
  runner.addCommand(MakeRelativeCommand());
  runner.addCommand(PatchCommand());
  runner.addCommand(WatchCommand());

  await runner.run(arguments);
}

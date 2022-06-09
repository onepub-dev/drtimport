/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart';
import 'package:path/path.dart' as p;

import 'dart_import_app.dart';
import 'src/version/version.g.dart';

class PatchCommand extends Command<void> {
  @override
  String get description =>
      '''Patches import statements by doing a string replace within every import statement.''';

  @override
  String get name => 'patch';

  DartProject _project;

  String _projectRoot;

  PatchCommand() {
    argParser.addOption('root',
        help: 'The path to the root of your project.', valueHelp: 'path');
    argParser.addFlag('debug',
        defaultsTo: false, negatable: false, help: 'Turns on debug ouput');
    argParser.addFlag('version',
        abbr: 'v',
        defaultsTo: false,
        negatable: false,
        help: 'Outputs the version of drtimport and exits.');
  }

  @override
  void run() {
    var root = argResults['root'] as String;

    root ??= pwd;

    if (argResults['version'] == true) {
      fullusage();
    }

    if (argResults['debug'] == true) DartImportApp().enableDebug();

    if (argResults.rest.length != 2) {
      fullusage();
    }

    _project = DartProject.fromPath(root);
    _projectRoot = _project.pathToProjectRoot;

    if (!_project.hasPubSpec) {
      fullusage(
          error:
              'The project root directory ${_projectRoot} does not contain a pubspec.yaml');
    }

    var pubspec = _project.pubSpec;
    print(orange('Processing project ${pubspec.name} in ${_projectRoot}'));

    // check we are in the root.
    if (!exists(join(_projectRoot, 'lib'))) {
      fullusage(
          error:
              'Your project structure looks invalid. You must have a "lib" directory in the root of your project.');
    }

    final fromPattern = argResults.rest[0];
    final toPattern = argResults.rest[1];

    process(fromPattern, toPattern);
  }

  void process(String fromPattern, String toPattern) async {
    final dartFiles =
        find('*.dart', workingDirectory: _project.pathToProjectRoot, recursive: true)
            .toList();

    var scanned = 0;
    var updated = 0;
    for (var file in dartFiles) {
      scanned++;
      final result = await replaceString(File(file), fromPattern, toPattern);
      final tmpFile = result.pathToTempFile;

      if (result.changeCount != 0) {
        updated++;
        var backupFile = '$file.bak';
        move(file, backupFile);
        move(tmpFile, file);
        delete(backupFile);

        print('Updated : ${file} changed ${result.changeCount} lines');
      }
    }
    print('Finished: scanned $scanned updated $updated');
  }

  Future<Result> replaceString(
      FileSystemEntity file, String fromPattern, String toPattern) async {
    final systemTempDir = Directory.systemTemp;

    final tmpPath = p.join(systemTempDir.path, file.path);
    final tmpFile = tmpPath;

    final tmpDir = p.dirname(tmpFile);
    await createDir(tmpDir, recursive: true);

    final tmpSink = File(tmpFile).openWrite();

    final result = Result(tmpFile);

    await File(file.path)
        .openRead()
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .forEach((line) => result.changeCount +=
            replaceLine(line, fromPattern, toPattern, tmpSink));

    return result;
  }

  int replaceLine(
      String line, String fromPattern, String toPattern, IOSink tmpSink) {
    var newLine = line;

    var changeCount = 0;

    if (line.startsWith('import')) {
      newLine = line.replaceAll(fromPattern, toPattern);
    }
    if (line != newLine) {
      changeCount++;
    }
    tmpSink.writeln(newLine);

    return changeCount;
  }

  void fullusage({String error}) {
    print('drtimport version: ${packageVersion}');
    print('Usage: ');
    print(description);
    print('<from string> <to string>');
    print('e.g. AppClass app_class');
    print(argParser.usage);

    exit(-1);
  }
}

class Result {
  String pathToTempFile;
  int changeCount = 0;

  Result(this.pathToTempFile);
}

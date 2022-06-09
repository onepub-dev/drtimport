/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */
import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:path/path.dart' as p;

import 'package:args/command_runner.dart';

import 'dart_import_app.dart';
import 'library.dart';
import 'line.dart';
import 'move_result.dart';
import 'src/version/version.g.dart';

class MoveCommand extends Command<void> {
  @override
  String get description =>
      '''Moves a dart library and updates all import statements to reflect its new location.
      move <from path> <to path>''';

  @override
  String get name => 'move';

  DartProject _project;
  String _projectRoot;

  String pathToLib;

  MoveCommand() {
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
  void run() async {
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
    pathToLib = p.join(_projectRoot, 'lib');

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

    Line.init(_project);
    var from = argResults.rest[0];
    var to = argResults.rest[1];
    importMove(from: join(_projectRoot, from), to: join(_projectRoot, to));
  }

  /// [alreadyMoved] means that the from path no longer exists
  /// as it has been moved by another system.
  /// In this case we just need to update the imports.
  void importMove({String from, String to, bool alreadyMoved = false}) async {
    if (isDirectory(from)) {
      await importMoveDirectory(from: from, to: to, alreadyMoved: alreadyMoved);
    } else {
      await moveFile(
          from: from, to: to, fromDirectory: false, alreadyMoved: alreadyMoved);
    }
  }

  void importMoveDirectory({String from, String to, bool alreadyMoved}) async {
    validateFrom(from, alreadyMoved);

    for (var entry in Directory(from).listSync()) {
      if (entry is File) {
        moveFile(
            from: entry.path,
            to: to,
            fromDirectory: true,
            alreadyMoved: alreadyMoved);
      }
    }
  }

  void moveFile(
      {String from, String to, bool fromDirectory, bool alreadyMoved}) {
    validateFrom(from, alreadyMoved);

    var toDir = to;
    if (to.endsWith('*.dart')) {
      toDir = dirname(to);
    }

    if (!exists(toDir)) createDir(toDir, recursive: true);

    if (isDirectory(to)) {
      // The [to] path is a directory so use the
      // fromPaths filename to complete the target pathname.
      to = p.join(to, p.basename(from));
    }

    if (!alreadyMoved) {
      print('Renaming: ${from} to ${to}');
      move(from, to);
    }

    final dartFiles = find('*.dart', workingDirectory: _projectRoot).toList();

    final updatedFiles = <ModifiedFile>[];
    var scanned = 0;
    var updated = 0;
    for (var library in dartFiles) {
      scanned++;

      final processing = Library(library, pathToLib);

      /// If this is the library we have just moved then
      /// we need to record its original location so its import
      /// statements are processed correctly against the original location.
      if (processing.pathToSourceFile == to) {
        processing.setFrom(from);
      }
      final modifiedFile = processing.updateImportStatements(from, to);

      if (modifiedFile.changeCount != 0) {
        updated++;
        updatedFiles.add(modifiedFile);

        print('Updated : ${library} changed ${modifiedFile.changeCount} lines');
      }
    }

    overwrite(updatedFiles);

    print('Finished: scanned $scanned updated $updated');
  }

  ///
  /// [from] can be a file or a path.
  ///
  void validateFrom(String from, bool alreadyMoved) {
    if (!alreadyMoved && !exists(from)) {
      fullusage(
          error: "The <fromPath> is not a valid filepath: '${truepath(from)}'");
    }
  }

  void overwrite(List<ModifiedFile> updatedFiles) {
    for (final result in updatedFiles) {
      result.library.overwrite(result.tmpFile);
      result.library.sortDirectives();
    }
  }

  String expandPath(String path) {
    return p.join('lib', path);
  }

  bool isDirectory(String path) {
    final fromType = FileSystemEntity.typeSync(expandPath(path));
    return (fromType == FileSystemEntityType.directory);
  }

  void fullusage({String error}) async {
    if (error != null) {
      print('Error: $error');
      print('');
    }

    print('drtimport version: ${packageVersion}');
    print('Usage: ');
    print('move <from path> <to path>');
    print('e.g. move apps/string.dart  util/string.dart');
    print(argParser.usage);

    exit(-1);
  }

  /// remove the leading lib/ prefix of the to/from paths
  String stripLib(String path) {
    if (path.startsWith('lib/')) {
      return path.substring('lib/'.length);
    } else {
      fullusage(error: 'The path "$path" must start with "lib/"');
      // will never happen as fullusage exits.
      return null;
    }
  }
}

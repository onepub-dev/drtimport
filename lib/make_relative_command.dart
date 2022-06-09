/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */
import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:drtimport/src/version/version.g.dart';
import 'package:path/path.dart' as p;

import 'package:args/command_runner.dart';

import 'dart_import_app.dart';
import 'library.dart';
import 'line.dart';
import 'move_result.dart';

class MakeRelativeCommand extends Command<void> {
  // This is the lib directory
  String pathToLib;
  @override
  String get description =>
      '''Changes all local package references into relative references.''';

  @override
  String get name => 'relative';

  DartProject _project;
  String _projectRoot;

  MakeRelativeCommand() {
    argParser.addOption('root',
        defaultsTo: '.',
        help: 'The path to the root of your project.',
        valueHelp: 'path');
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

    await process();
  }

  void process() async {
    final dartFiles = find('*.dart', workingDirectory: _projectRoot).toList();

    final updatedFiles = <ModifiedFile>[];
    var scanned = 0;
    var updated = 0;
    for (var library in dartFiles) {
      scanned++;

      /// print('checking within $library');

      /// relative paths are only applicable to files in the lib dir.
      if (!isWithin(pathToLib, library)) continue;

      print('processing $library');

      final processing = Library(library, pathToLib);
      final result = await processing.makeImportsRelative();

      if (result.changeCount != 0) {
        updated++;
        updatedFiles.add(result);

        print('Updated : ${library} changed ${result.changeCount} lines');
      }
    }

    await overwrite(updatedFiles);

    print('Finished: scanned $scanned updated $updated');
  }

  ///
  /// [from] can be a file or a path.
  ///
  String validFrom(String from) {
    // all file paths are relative to lib/ but
    // the imports don't include lib so devs
    // will just pass in the name as the see it in the import statement (e.g. no lib)
    // but when we are validating the actual path we need the lib.

    if (!exists(from)) {
      fullusage(
          error: "The <fromPath> is not a valid filepath: '${truepath(from)}'");
    }
    return from;
  }

  ///
  /// [from] can be a file or a path.
  ///
  String validFromDirectory(String from) {
    // all file paths are relative to lib/ but
    // the imports don't include lib so devs
    // will just pass in the name as they see it in the import statement (e.g. no lib)
    // but when we are validating the actual path we need the lib.

    if (!exists(from)) {
      fullusage(
          error: "The <fromPath> is not a valid filepath: '${truepath(from)}'");
    }
    return from;
  }

  ///
  /// [to] can be a file or a path.
  ///
  String validTo(String to) {
    // will just pass in the name as they see it in the import statement (e.g. no lib)
    // but when we are validating the actual path we need the lib.

    if (to.endsWith('.dart')) {
      if (!exists(to)) {
        return to;
      } else {
        fullusage(
            error:
                'The <toPath> dart file already exist. You can not move over an existing file');
      }
    } else {
      if (!exists(to)) {
        fullusage(
            error: 'The <toPath> directory does not exist: ${truepath(to)}');
      }
    }
    return to;
  }

  void overwrite(List<ModifiedFile> updatedFiles) async {
    for (final result in updatedFiles) {
      await result.library.overwrite(result.tmpFile);
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
    print('relative');
    print('e.g. changes all local imports to relative imports.');
    print(argParser.usage);
  }
}

import 'dart:io';

import 'package:dshell/dshell.dart';
import 'package:path/path.dart' as p;

import 'package:args/command_runner.dart';

import 'dart_import_app.dart';
import 'library.dart';
import 'line.dart';
import 'move_result.dart';
import 'pubspec.dart';

class MakeRelativeCommand extends Command<void> {
  // This is the lib directory
  Directory libRoot;
  @override
  String get description =>
      '''Changes all local package references into relative references.''';

  @override
  String get name => 'relative';

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
    Directory.current = argResults['root'];
    libRoot = Directory(p.join(Directory.current.path, 'lib'));

    if (argResults['version'] == true) {
      fullusage();
    }

    if (argResults['debug'] == true) DartImportApp().enableDebug();

    if (argResults.rest.length != 2) {
      fullusage();
    }
    if (!await File('pubspec.yaml').exists()) {
      fullusage(
          error: 'The pubspec.yaml is missing from: ${Directory.current}');
    }

    // check we are in the root.
    if (!await libRoot.exists()) {
      fullusage(error: 'You must run a move from the root of the package.');
    }

    Line.init();

    if (DartImportApp().isdebugging) {
      print('Package Name: ${Line.getProjectName()}');
    }

    await process();
  }

  void process() async {
    final dartFiles = find('*.dart', root: pwd).toList();

    final updatedFiles = <ModifiedFile>[];
    var scanned = 0;
    var updated = 0;
    for (var library in dartFiles) {
      scanned++;

      final processing = Library(File(library), libRoot);
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
  Future<File> validFrom(String from) async {
    // all file paths are relative to lib/ but
    // the imports don't include lib so devs
    // will just pass in the name as the see it in the import statement (e.g. no lib)
    // but when we are validating the actual path we need the lib.

    final actualPath = File(p.canonicalize(p.join('lib', from)));

    if (!await actualPath.exists()) {
      fullusage(
          error:
              "The <fromPath> is not a valid filepath: '${actualPath.path}'");
    }
    return actualPath;
  }

  ///
  /// [from] can be a file or a path.
  ///
  Future<Directory> validFromDirectory(String from) async {
    // all file paths are relative to lib/ but
    // the imports don't include lib so devs
    // will just pass in the name as they see it in the import statement (e.g. no lib)
    // but when we are validating the actual path we need the lib.

    final actualPath = Directory(p.canonicalize(p.join('lib', from)));

    if (!await actualPath.exists()) {
      fullusage(
          error:
              "The <fromPath> is not a valid filepath: '${actualPath.path}'");
    }
    return actualPath;
  }

  ///
  /// [to] can be a file or a path.
  ///
  Future<File> validTo(String to) async {
    // all file paths are relative to lib/ but
    // the imports don't include lib so devs
    // will just pass in the name as they see it in the import statement (e.g. no lib)
    // but when we are validating the actual path we need the lib.
    final actualPath = File(p.canonicalize(p.join('lib', to)));
    if (!await actualPath.parent.exists()) {
      fullusage(
          error: 'The <toPath> directory does not exist: ${actualPath.parent}');
    }
    return actualPath;
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

    final pubSpec = PubSpec();
    await pubSpec.load();
    final version = pubSpec.version;
    print('drtimport version: ${version}');
    print('Usage: ');
    print('move <from path> <to path>');
    print('e.g. move apps/string.dart  util/string.dart');
    print(argParser.usage);

    exit(-1);
  }
}

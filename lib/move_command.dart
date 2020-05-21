import 'dart:io';

import 'package:dshell/dshell.dart';
import 'package:path/path.dart' as p;

import 'package:args/command_runner.dart';

import 'dart_import_app.dart';
import 'library.dart';
import 'line.dart';
import 'move_result.dart';
import 'pubspec.dart';

class MoveCommand extends Command<void> {
  @override
  String get description =>
      '''Moves a dart library and updates all import statements to reflect its new location.
      move <from path> <to path>''';

  @override
  String get name => 'move';

  MoveCommand() {
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
    if (!await Directory('lib').exists()) {
      fullusage(error: 'You must run a move from the root of the package.');
    }
    if (DartImportApp().isdebugging) {
      print('Package Name: ${Line.getProjectName()}');
    }

    Line.init();
    move(from: argResults.rest[0], to: argResults.rest[1]);
  }

  /// [alreadyMoved] means that the from path no longer exists
  /// as it has been moved by another system.
  /// In this case we just need to update the imports.
  void move({String from, String to, bool alreadyMoved = false}) async {
    if (isDirectory(from)) {
      await moveDirectory(from: from, to: to, alreadyMoved: alreadyMoved);
    } else {
      await moveFile(
          from: from, to: to, fromDirectory: false, alreadyMoved: alreadyMoved);
    }
  }

  void moveDirectory({String from, String to, bool alreadyMoved}) async {
    validateFrom(from, alreadyMoved);

    for (var entry in Directory(from).listSync()) {
      if (entry is File) {
        await moveFile(
            from: entry.path,
            to: to,
            fromDirectory: true,
            alreadyMoved: alreadyMoved);
      }
    }
  }

  void moveFile(
      {String from, String to, bool fromDirectory, bool alreadyMoved}) async {
    validateFrom(from, alreadyMoved);
    var libRoot = Directory(p.join(Directory.current.path, 'lib'));
    if (isDirectory(to)) {
      // The [to] path is a directory so use the
      // fromPaths filename to complete the target pathname.
      to = p.join(to, p.basename(from));
    } else {
      if (fromDirectory) {
        // The target must also be a directory and it must exist
        fullusage(
            error:
                'The <to> path ${expandPath(to)} MUST be a directory and it must exist');
      }
    }

    validateTo(to);

    if (!alreadyMoved) {
      print('Renaming: ${from} to ${to}');
    }

    final dartFiles = find('*.dart', root: pwd).toList();

    final updatedFiles = <ModifiedFile>[];
    var scanned = 0;
    var updated = 0;
    for (var library in dartFiles) {
      scanned++;

      final processing = Library(File(library), libRoot);
      final result = await processing.updateImportStatements(from, to);

      if (result.changeCount != 0) {
        updated++;
        updatedFiles.add(result);

        print('Updated : ${library} changed ${result.changeCount} lines');
      }
    }

    await overwrite(updatedFiles);

    if (!alreadyMoved) {
      await File(from).exists();

      await File(from).rename(to);
    }
    print('Finished: scanned $scanned updated $updated');
  }

  ///
  /// [from] can be a file or a path.
  ///
  void validateFrom(String from, bool alreadyMoved) {
    if (!alreadyMoved && !File(from).existsSync()) {
      fullusage(error: "The <fromPath> is not a valid filepath: '${from}'");
    }
  }

  ///
  /// [to] can be a file or a path.
  ///
  void validateTo(String to) {
    if (!File(to).existsSync()) {
      fullusage(error: 'The <toPath> directory does not exist: ${dirname(to)}');
    }
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

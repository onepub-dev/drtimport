import 'dart:async';
import 'dart:io';

import 'package:drtimport/move_command.dart';
import 'package:dshell/dshell.dart';
import 'package:path/path.dart' as p;

import 'package:args/command_runner.dart';
import 'package:pedantic/pedantic.dart';

import 'dart_import_app.dart';
import 'line.dart';
import 'pubspec.dart';

class WatchCommand extends Command<void> {
  // This is the lib directory
  Directory libRoot;
  @override
  String get description =>
      '''Changes all local package references into relative references.''';

  @override
  String get name => 'watch';

  WatchCommand() {
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
      exit(-1);
    }

    if (argResults['debug'] == true) DartImportApp().enableDebug();

    if (argResults.rest.isNotEmpty) {
      fullusage();
      exit(-1);
    }
    if (!await File('pubspec.yaml').exists()) {
      fullusage(
          error: 'The pubspec.yaml is missing from: ${Directory.current}');
      exit(-1);
    }

    // check we are in the root.
    if (!await libRoot.exists()) {
      fullusage(error: 'You must run a move from the root of the package.');
      exit(-1);
    }

    Line.init();

    if (DartImportApp().isdebugging) {
      print('Package Name: ${Line.getProjectName()}');
    }

    await process();
  }

  void process() async {
    Settings().setVerbose(true);
    print('scanning for directoryies in $pwd');
    final directories = find('*',
        root: libRoot.path,
        recursive: true,
        types: [FileSystemEntityType.directory]).toList();

    var controller = StreamController<FileSystemEvent>();
    controller.stream.listen((event) => onMove(event));

    print('watching ${libRoot.path}');
    libRoot
        .watch(events: FileSystemEvent.move | FileSystemEvent.modify)
        .listen((event) => controller.add(event));

    /// start a watch on every subdirectory of lib
    for (var directory in directories) {
      print('watching $directory');

      /// we don't use recursive watch as not supported on all platforms.
      Directory(directory)
          .watch(events: FileSystemEvent.move | FileSystemEvent.modify)
          .listen((event) => controller.add(event));
    }

    var forever = Completer<void>();

    // wait until someone does ctrl-c.
    await forever.future;
  }

  void onMove(FileSystemEvent event) {
    if (event is FileSystemModifyEvent) {
      print('dected modify');
      print(
          'details: directory: ${event.isDirectory} ${event.path} content: ${event.contentChanged}');
    } else if (event is FileSystemMoveEvent) {
      var actioned = false;

      print('dected move');
      print(
          'details: directory: ${event.isDirectory} ${event.path} destination: ${event.destination}');
      if (event.isDirectory) {
        actioned = true;
        MoveCommand().move(
            from: libRelative(event.path), to: libRelative(event.destination));
      } else {
        if (extension(event.path) == '.dart') {
          actioned = true;
          MoveCommand().move(
              from: libRelative(event.path),
              to: libRelative(event.destination));
        }
      }
      if (actioned) {
        print('actioned');
      } else {
        print('ignored');
      }
    }
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
    print('relative');
    print('e.g. changes all local imports to relative imports.');
    print(argParser.usage);
  }

  bool isUnderLib(String path) {
    var relpath = relative(path, from: libRoot.path);

    return !relpath.startsWith('..');
  }

  String libRelative(String path) {
    return join('lib', relative(path, from: libRoot.path));
  }
}

import 'dart:async';
import 'dart:io';

import 'package:drtimport/move_command.dart';
import 'package:dcli/dcli.dart';
import 'package:path/path.dart' as p;

import 'package:args/command_runner.dart';

import 'dart_import_app.dart';
import 'line.dart';

class WatchCommand extends Command<void> {
  var controller = StreamController<FileSystemEvent>();
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
    Settings().setVerbose(enabled: true);
    print('scanning for directoryies in $pwd');
    final directories = find('*',
        root: libRoot.path,
        recursive: true,
        types: [FileSystemEntityType.directory]).toList();

    StreamSubscription<FileSystemEvent> subscriber;
    subscriber = controller.stream.listen((event) async {
      // serialise the events
      // otherwise we end up trying to move multiple files
      // at once and that doesn't work.
      subscriber.pause();
      await onFileSystemEvent(event);
      subscriber.resume();
    });

    watchDirectory(libRoot);

    /// start a watch on every subdirectory of lib
    for (var directory in directories) {
      watchDirectory(Directory(directory));
    }

    var forever = Completer<void>();

    // wait until someone does ctrl-c.
    await forever.future;
  }

  void watchDirectory(Directory directory) {
    print('watching ${directory.path}');
    directory
        .watch(events: FileSystemEvent.all)
        .listen((event) => controller.add(event));
  }

  void onFileSystemEvent(FileSystemEvent event) async {
    if (event is FileSystemCreateEvent) {
      await onCreateEvent(event);
    } else if (event is FileSystemModifyEvent) {
      await onModifyEvent(event);
    } else if (event is FileSystemMoveEvent) {
      await onMoveEvent(event);
    } else if (event is FileSystemDeleteEvent) {
      await onDeleteEvent(event);
    }
  }

  void onModifyEvent(FileSystemModifyEvent event) async {
    // print(blue('detected modify'));
    // print(
    //     'details: directory: ${event.isDirectory} ${event.path} content: ${event.contentChanged}');
  }

  void onCreateEvent(FileSystemCreateEvent event) async {
    if (event.isDirectory) {
      Directory(event.path)
          .watch(events: FileSystemEvent.all)
          .listen((event) => controller.add(event));
      print('Added directory watch to ${event.path}');
    } else {
      print(blue('File created at ${event.path}'));
      if (lastDeleted != null) {
        if (basename(event.path) == basename(lastDeleted)) {
          print(red('Move from: $lastDeleted to: ${event.path}'));
          await MoveCommand().moveFile(
              from: lastDeleted,
              to: event.path,
              fromDirectory: false,
              alreadyMoved: true);
          print(red('Completed move from: $lastDeleted to: ${event.path}'));
          lastDeleted = null;
        }
      }
    }
  }

  String lastDeleted;

  void onDeleteEvent(FileSystemDeleteEvent event) async {
    print('Delete: directory: ${event.isDirectory} ${event.path}');
    if (!event.isDirectory) {
      lastDeleted = event.path;
    }
  }

  void onMoveEvent(FileSystemMoveEvent event) async {
    var actioned = false;

    var from = event.path;
    var to = event.destination;

    if (event.isDirectory) {
      actioned = true;
      await MoveCommand().moveDirectory(
          from: libRelative(from), to: libRelative(to), alreadyMoved: true);
    } else {
      if (extension(from) == '.dart') {
        /// we don't process the move if the 'to' isn't a dart file.
        /// e.g. ignore a target of <lib>.dart.bak
        if (isDirectory(to) || isFile(to) && extension(to) == '.dart') {
          actioned = true;
          await MoveCommand().moveFile(
              from: libRelative(from),
              to: libRelative(to),
              fromDirectory: false,
              alreadyMoved: true);
        }
      }
    }
    if (actioned) {
      print(
          'Move: directory: ${event.isDirectory} ${event.path} destination: ${event.destination}');
    }
  }

  void fullusage({String error}) async {
    if (error != null) {
      print('Error: $error');
      print('');
    }

    final pubSpec = DartProject.fromPath('.', search: true).pubSpec;
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

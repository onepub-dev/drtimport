import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:args/args.dart';
import 'package:args/command_runner.dart';

class PatchCommand extends Command<void> {
  @override
  String get description =>
      '''Patches import statements by doing a string replace within every import statement.''';

  @override
  String get name => 'patch';

  @override
  void run() {
    if (argResults.rest.length != 2) {
      fullusage(argParser);
      exit(-1);
    }
    final fromPattern = argResults.rest[0];
    final toPattern = argResults.rest[1];

    process(fromPattern, toPattern);
  }

  void process(String fromPattern, String toPattern) async {
    final cwd = Directory('.');

    final files = cwd.list(recursive: true);

    final dartFiles =
        await files.where((file) => file.path.endsWith('.dart')).toList();

    var scanned = 0;
    var updated = 0;
    for (var file in dartFiles) {
      scanned++;
      final result = await replaceString(file, fromPattern, toPattern);
      final tmpFile = result.tmpFile;

      if (result.changeCount != 0) {
        updated++;
        final backupFile = await file.rename(file.path + '.bak');
        await tmpFile.rename(file.path);
        await backupFile.delete();

        print('Updated : ${file.path} changed ${result.changeCount} lines');
      }
    }
    print('Finished: scanned $scanned updated $updated');
  }

  Future<Result> replaceString(
      FileSystemEntity file, String fromPattern, String toPattern) async {
    final systemTempDir = Directory.systemTemp;

    final tmpPath = p.join(systemTempDir.path, file.path);
    final tmpFile = File(tmpPath);

    final tmpDir = Directory(tmpFile.parent.path);
    await tmpDir.create(recursive: true);

    final tmpSink = tmpFile.openWrite();

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

  void fullusage(ArgParser parser) {
    print('Usage: ');
    print(description);
    print('<from string> <to string>');
    print('e.g. AppClass app_class');
    print(parser.usage);
  }
}

class Result {
  File tmpFile;
  int changeCount = 0;

  Result(this.tmpFile);
}

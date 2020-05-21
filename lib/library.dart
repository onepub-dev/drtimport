import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'dart_import_app.dart';
import 'line.dart';
import 'move_result.dart';

class Library {
  File sourceFile;
  bool externalLib;
  Directory libRoot;

  /// If this library was moved then this will
  /// contain its original path.
  String from;

  Library(this.sourceFile, this.libRoot) {
    externalLib = !_isUnderLibRoot();

    if (sourceFile.path.endsWith('office_holidays_dashlet.dart')) {
      DartImportApp().debug('office_holidays_dashlet');
    }

    DartImportApp()
        .debug('Processing: ${sourceFile} externalLib: $externalLib');
  }

  // File get file => sourceFile;

  bool get isExternal => externalLib;

  String get directory => sourceFile.parent.path;

  /// returns the directory where the library hails from.
  /// For most libraries this is the current location but
  /// for the one library we are moving this will be its original
  /// path.
  /// This is important for processing import statements which
  /// will be relative to the original libraries location.
  String get originalDirectory =>
      (from == null ? sourceFile.parent.path : p.dirname(from));

  ///
  /// Returns true if the library is under the lib directory
  bool _isUnderLibRoot() {
    return p.isWithin(libRoot.path, sourceFile.path);
  }

  Future<File> createTmpFile() async {
    final systemTempDir = Directory.systemTemp;

    final tmpFile =
        File(p.join(systemTempDir.path, p.relative(sourceFile.path)));

    final tmpDir = Directory(tmpFile.parent.path);
    await tmpDir.create(recursive: true);

    return tmpFile;
  }

  void overwrite(File tmpFile) async {
    FileSystemEntity backupFile =
        await sourceFile.rename(sourceFile.path + '.bak');
    await tmpFile.rename(sourceFile.path);
    await backupFile.delete();
  }

  /// Updates any the import statements in the passed
  /// dart [libraryFile] that refer to [fromPath]
  /// so that they now point to 'toPath'.
  /// [fromPath] and [toPath] are [File]s relative to the lib directory.
  ///
  Future<ModifiedFile> updateImportStatements(
      String fromPath, String toPath) async {
    // Create temp file to write changes to.
    final tmpFile = await createTmpFile();

    final tmpSink = tmpFile.openWrite();

    final result = ModifiedFile(this, tmpFile);

    // print('Scanning: ${file.path}');

    await sourceFile
        .openRead()
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .forEach((line) async => result.changeCount +=
            await replaceLine(line, File(fromPath), File(toPath), tmpSink));

    await tmpSink.flush();
    await tmpSink.close();

    return result;
  }

  Future<ModifiedFile> makeImportsRelative() async {
    // Create temp file to write changes to.
    final tmpFile = await createTmpFile();
    final result = ModifiedFile(this, tmpFile);
    final tmpSink = tmpFile.openWrite();

    await sourceFile
        .openRead()
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .forEach((rawLine) {
      //    result.changeCount += replaceLine(line, fromPath, toPath, tmpSink));

      final line = Line(this, rawLine);

      var newLine = line.makeRelative(this);

      if (rawLine != newLine) {
        result.changeCount++;
      }

      tmpSink.writeln(newLine);
    });

    await tmpSink.flush();
    await tmpSink.close();
    return result;
  }

  int replaceLine(String rawLine, File fromPath, File toPath, IOSink tmpSink) {
    var newLine = rawLine;

    var changeCount = 0;

    final line = Line(this, rawLine);
    newLine = line.update(this, fromPath, toPath);

    if (rawLine != newLine) {
      changeCount++;
    }
    tmpSink.writeln(newLine);

    return changeCount;
  }

  void setFrom(String from) {
    this.from = from;
  }
}

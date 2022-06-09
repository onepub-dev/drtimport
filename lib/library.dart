/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:dcli/dcli.dart';

import 'dart_import_app.dart';
import 'line.dart';
import 'move_result.dart';

class Library {
  String pathToSourceFile;
  bool externalLib;
  String pathToLib;

  /// If this library was moved then this will
  /// contain its original path.
  String from;

  Library(this.pathToSourceFile, this.pathToLib) {
    externalLib = !_isUnderLibRoot();

    if (pathToSourceFile.endsWith('office_holidays_dashlet.dart')) {
      DartImportApp().debug('office_holidays_dashlet');
    }

    DartImportApp()
        .debug('Processing: ${pathToSourceFile} externalLib: $externalLib');
  }

  // File get file => sourceFile;

  bool get isExternal => externalLib;

  String get directory => p.dirname(pathToSourceFile);

  /// returns the directory where the library hails from.
  /// For most libraries this is the current location but
  /// for the one library we are moving this will be its original
  /// path.
  /// This is important for processing import statements which
  /// will be relative to the original libraries location.
  String get originalDirectory =>
      (from == null ? p.dirname(pathToSourceFile) : p.dirname(from));

  ///
  /// Returns true if the library is under the lib directory
  bool _isUnderLibRoot() {
    return p.isWithin(pathToLib, pathToSourceFile);
  }

  String createTmpFile() {
    var tmpFile = createTempFilename();
    touch(tmpFile, create: true);

    return tmpFile;
  }

  void overwrite(File tmpFile) {
    var backupFile = pathToSourceFile + '.bak';
    move(pathToSourceFile, backupFile);
    move(tmpFile.path, pathToSourceFile);
    delete(backupFile);
  }

  /// Updates any the import statements in the passed
  /// dart [libraryFile] that refer to [fromPath]
  /// so that they now point to 'toPath'.
  /// [fromPath] and [toPath] are [File]s relative to the lib directory.
  ///
  ModifiedFile updateImportStatements(String fromPath, String toPath) {
    // Create temp file to write changes to.
    final tmpFile = File(createTmpFile());

    final tmpSink = tmpFile.openWrite();

    final result = ModifiedFile(this, tmpFile);

    // print('Scanning: ${file.path}');

    waitForEx<void>(File(pathToSourceFile)
        .openRead()
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .forEach((line) {
      var changes = replaceLine(line, File(fromPath), File(toPath), tmpSink);
      result.changeCount += changes;
    }));

    waitForEx<void>(tmpSink.flush());
    waitForEx<void>(tmpSink.close());

    return result;
  }

  Future<ModifiedFile> makeImportsRelative() async {
    // Create temp file to write changes to.
    final tmpFile = File(createTmpFile());
    final result = ModifiedFile(this, tmpFile);
    final tmpSink = tmpFile.openWrite();

    await File(pathToSourceFile)
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

  /// sorts an files import directives.
  /// We use the location of the first import statement as the insertion
  /// point for all directives
  void sortDirectives() {
    var importLines = <String>[];
    var otherLines = <String>[];
    var firstImport = -1;
    var lines = read(pathToSourceFile).toList();

    var backupFile = pathToSourceFile + '.bak';
    move(pathToSourceFile, backupFile);

    touch(pathToSourceFile, create: true);

    var count = 0;
    for (var line in lines) {
      if (line.trim().startsWith("import '")) {
        importLines.add(line);

        if (firstImport == -1) {
          firstImport = count;
        }
      } else {
        otherLines.add(line);
      }
      count++;
    }

    sortImports(importLines);

    count = 0;
    for (var line in otherLines) {
      if (count == firstImport) {
        for (var import in importLines) {
          pathToSourceFile.append(import);
        }
      }
      pathToSourceFile.append(line);
      count++;
    }

    delete(backupFile);
  }

  void sortImports(List<String> importLines) {
    importLines.sort((lhs, rhs) {
      var lhsval = 0;
      var rhsval = 0;
      if (lhs.contains('dart:')) lhsval = 10;
      if (rhs.contains('dart:')) rhsval = 10;

      if (lhsval != rhsval) return rhsval - lhsval;

      if (lhs.contains('package:')) lhsval = 100;
      if (rhs.contains('package:')) rhsval = 100;

      if (lhsval != rhsval) return rhsval - lhsval;

      return lhs.compareTo(rhs);
    });
  }
}

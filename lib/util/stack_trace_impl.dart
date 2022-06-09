/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */
import 'dart:core' as core show StackTrace;
import 'dart:core';
import 'dart:io';

import 'package:path/path.dart';

class StackTraceImpl implements core.StackTrace {
  static final stackTraceRegex = RegExp(r'#[0-9]+[\s]+(.+) \(([^\s]+)\)');
  final core.StackTrace stackTrace;

  final String workingDirectory;
  final int _skipFrames;

  List<Stackframe> _frames;

  /// You can suppress call frames from showing
  /// by specifing a non-zero value for [skipFrames]
  /// If the workingDirectory is provided we will output
  /// a full file path to the dart library.
  StackTraceImpl({int skipFrames = 0, this.workingDirectory})
      : stackTrace = core.StackTrace.current,
        _skipFrames = skipFrames + 1; // always skip ourselves.

  ///
  /// Returns a File instance for the current stackframe
  ///
  File get sourceFile {
    return frames[0].sourceFile;
  }

  ///
  /// Returns the Filename for the current stackframe
  ///
  String get sourceFilename => basename(sourcePath);

  ///
  /// returns the full path for the current stackframe file
  ///
  String get sourcePath => sourceFile.path;

  ///
  /// Returns the filename for the current stackframe
  ///
  int get lineNo {
    return frames[0].lineNo;
  }

  /// Outputs a formatted string of the current stack_trace_nj
  /// showing upto [methodCount] methods in the trace.
  /// [methodCount] defaults to 10.

  String formatStackTrace({bool showPath = false, int methodCount = 10}) {
    var formatted = <String>[];
    var count = 0;

    for (final stackFrame in frames) {
      // if (stackFrame.sourceFile.contains('log.dart') ||
      //     stackFrame.sourceFile.contains('package:logger')) {
      //   continue;
      // }

      String sourceFile;
      if (showPath) {
        sourceFile = stackFrame.sourceFile.path;
      } else {
        sourceFile = basename(stackFrame.sourceFile.path);
      }
      var newLine = ('${sourceFile}:${stackFrame.lineNo}');

      if (workingDirectory != null) {
        formatted.add('file:///' + workingDirectory + newLine);
      } else {
        formatted.add(newLine);
      }
      if (++count == methodCount) {
        break;
      }
    }

    if (formatted.isEmpty) {
      return null;
    } else {
      return formatted.join('\n');
    }
  }

  List<Stackframe> get frames {
    _frames ??= _extractFrames();
    return _frames;
  }

  @override
  String toString() {
    return formatStackTrace();
  }

  List<Stackframe> _extractFrames() {
    var lines = stackTrace.toString().split('\n');

    // we don't want the call to StackTrace to be on the stack.
    var skipFrames = _skipFrames;

    var stackFrames = <Stackframe>[];
    for (var line in lines) {
      if (skipFrames > 0) {
        skipFrames--;
        continue;
      }
      var match = stackTraceRegex.matchAsPrefix(line);
      if (match == null) continue;

      // source is one of two formats
      // file:///.../package/filename.dart:column:line
      // package:/package/.path./filename.dart:column:line
      final source = match.group(2);
      final sourceParts = source.split(':');
      ArgumentError.value(sourceParts.length == 4,
          "Stackframe source does not contain the expeted no of colons '$source'");

      var column = '0';
      var lineNo = '0';
      var sourcePath = sourceParts[1];
      if (sourceParts.length > 2) {
        lineNo = sourceParts[2];
      }
      if (sourceParts.length > 3) {
        column = sourceParts[3];
      }

      // the actual contents of the line (sort of)
      final details = match.group(1);

      sourcePath = sourcePath.replaceAll('<anonymous closure>', '()');
      sourcePath = sourcePath.replaceAll('package:', '');
      // sourcePath = sourcePath.replaceFirst('<package_name>', '/lib');

      final frame = Stackframe(
          File(sourcePath), int.parse(lineNo), int.parse(column), details);
      stackFrames.add(frame);
    }
    return stackFrames;
  }
}

///
/// A single frame from a stack trace.
/// Holds the sourceFile name and line no.
///
class Stackframe {
  final File sourceFile;
  final int lineNo;
  final int column;
  final String details;

  Stackframe(this.sourceFile, this.lineNo, this.column, this.details);
}

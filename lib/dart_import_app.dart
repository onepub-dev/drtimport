/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */
class DartImportApp {
  static final DartImportApp _self = DartImportApp._internal();

  bool _debug = false;

  factory DartImportApp() {
    return _self;
  }

  DartImportApp._internal();

  void enableDebug() => _debug = true;

  bool get isdebugging => _debug;

  void debug(String line) {
    if (isdebugging) {
      print('DEBUG: ${line}');
    }
  }
}

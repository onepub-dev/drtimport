/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */
import 'dart:io';

import 'library.dart';

class ModifiedFile {
  Library _library;
  File tmpFile;
  int changeCount = 0;

  ModifiedFile(Library library, this.tmpFile) {
    _library = library;
  }

  Library get library => _library;
}

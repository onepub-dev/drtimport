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

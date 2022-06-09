/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */
import 'dart:io';

import 'package:yaml/yaml.dart';

class Yaml {
  String filename;
  YamlDocument document;

  Yaml(this.filename);

  void load() async {
    final contents = await File(filename).readAsString();
    document = loadYamlDocument(contents);
  }

  /// reads the project name from the yaml file
  ///
  String getValue(String key) {
    return document.contents.value[key] as String;
  }
}

import 'dart:io';

import 'package:yaml/yaml.dart';

void main() async {
  await getProjectName();
}

/// reads the project name from the yaml file
///
Future<String> getProjectName() async {
  final contents = await File('pubspec.yaml').readAsString();

  final pubSpec = loadYamlDocument(contents);
  print(pubSpec.contents.value['name']);
  return pubSpec.contents.value['name'] as String;
}

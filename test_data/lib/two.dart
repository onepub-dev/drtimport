import 'dart:math';

import 'package:path/path.dart';

import 'package:test_project/one.dart';

int add(int a, int b) {
  return a + b;
}

String test_path() {
  return join('/', 'abc');
}

int test_maths() {
  return min(1, 3);
}

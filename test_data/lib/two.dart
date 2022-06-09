/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */
import 'dart:math';

import 'package:path/path.dart';

import 'one.dart';

int add(int a, int b) {
  return a + b;
}

String test_path() {
  return join('/', 'abc');
}

int test_maths() {
  return min(1, 3);
}
